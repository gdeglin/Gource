/*
    Copyright (C) 2012 Andrew Caudwell (acaudwell@gmail.com)

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version
    3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "logmill.h"
#include "gource_settings.h"

#include "formats/git.h"
#include "formats/gitraw.h"
#include "formats/custom.h"
#include "formats/hg.h"
#include "formats/bzr.h"
#include "formats/svn.h"
#include "formats/apache.h"
#include "formats/cvs-exp.h"
#include "formats/cvs2cl.h"

#include <boost/filesystem.hpp>
#include <boost/format.hpp>

#include <fstream>
#include <map>
#include <queue>
#include <vector>

extern "C" {

    static int logmill_thread(void *lmill) {

        RLogMill *logmill = static_cast<RLogMill*> (lmill);
        logmill->run();

        return 0;
    }

};

namespace {

struct MergeSource {
    std::string label;
    std::string resolved_path;
    RCommitLog* log;
    RCommit commit;

    MergeSource() : log(0) {}
};

struct MergeItem {
    time_t timestamp;
    std::string label;
    std::string username;
    size_t source_index;
    size_t sequence;
};

struct MergeItemCompare {
    bool operator()(const MergeItem& a, const MergeItem& b) const {
        if(a.timestamp != b.timestamp) return a.timestamp > b.timestamp;
        if(a.label != b.label) return a.label > b.label;
        if(a.username != b.username) return a.username > b.username;
        return a.sequence > b.sequence;
    }
};

bool createMergedTempFile(std::string& path) {
    boost::filesystem::path temp_path =
        boost::filesystem::temp_directory_path() /
        boost::filesystem::unique_path("gource-%%%%-%%%%-%%%%.log");

    std::ofstream out(temp_path.string().c_str());
    if(!out.is_open()) return false;

    out.close();
    path = temp_path.string();
    return true;
}

bool readNextCommit(RCommitLog* log, RCommit& commit) {
    while(log->hasBufferedCommit() || !log->isFinished()) {
        if(log->nextCommit(commit)) return true;
        if(!log->isSeekable()) break;
    }

    return false;
}

std::string sanitiseRepoLabel(const std::string& value) {
    std::string label = value;

    if(label.empty()) label = "repo";

    for(size_t i=0; i<label.size(); i++) {
        if(label[i] == '|' || label[i] == '\n' || label[i] == '\r') {
            label[i] = '_';
        }
    }

    return label;
}

std::string repoLabelForPath(const std::string& path, std::map<std::string, int>& seen_labels) {
    boost::filesystem::path fs_path(path);

    std::string base_label;
    if(boost::filesystem::is_directory(fs_path)) {
        base_label = fs_path.filename().string();
    } else {
        base_label = fs_path.stem().string();
        if(base_label.empty()) {
            base_label = fs_path.filename().string();
        }
    }

    base_label = sanitiseRepoLabel(base_label);

    int count = ++seen_labels[base_label];
    if(count == 1) return base_label;

    return str(boost::format("%s-%d") % base_label % count);
}

std::string colourToHex(const vec3& colour) {
    int r = glm::clamp((int) (colour.x * 255.0f + 0.5f), 0, 255);
    int g = glm::clamp((int) (colour.y * 255.0f + 0.5f), 0, 255);
    int b = glm::clamp((int) (colour.z * 255.0f + 0.5f), 0, 255);

    char colour_string[16];
    snprintf(colour_string, sizeof(colour_string), "%02X%02X%02X", r, g, b);

    return colour_string;
}

std::string prefixRepoPath(const std::string& repo_label, const std::string& path) {
    std::string prefixed_path = "/" + repo_label;

    if(path.empty()) return prefixed_path;

    if(path[0] != '/') prefixed_path += "/";
    prefixed_path += path;

    return prefixed_path;
}

}

RLogMill::RLogMill(const std::string& logfile)
    : logfile(logfile) {

    logmill_thread_state = LOGMILL_STATE_STARTUP;
    clog = 0;
    merged_logfile.clear();

#if SDL_VERSION_ATLEAST(2,0,0)
    thread = SDL_CreateThread( logmill_thread, "logmill", this );
#else
    thread = SDL_CreateThread( logmill_thread, this );
#endif
}

RLogMill::~RLogMill() {

    abort();

    if(clog) delete clog;
    if(!merged_logfile.empty()) remove(merged_logfile.c_str());
}

void RLogMill::run() {
    logmill_thread_state = LOGMILL_STATE_FETCHING;

#if defined(HAVE_PTHREAD) && !defined(_WIN32)
    sigset_t mask;
    sigemptyset(&mask);

    // unblock SIGINT so user can cancel
    // NOTE: assumes SDL is using pthreads

    sigaddset(&mask, SIGINT);
    pthread_sigmask(SIG_UNBLOCK, &mask, 0);
#endif

    std::string log_format = gGourceSettings.log_format;

    try {

        if(gGourceSettings.hasMultiplePaths()) {
            clog = fetchMergedLog(log_format);
        } else {
            clog = fetchLog(log_format);
        }

        // find first commit after start_timestamp if specified
        if(clog != 0 && gGourceSettings.start_timestamp != 0) {

            RCommit commit;

            while(!gGourceSettings.shutdown && !clog->isFinished()) {

                if(clog->nextCommit(commit) && commit.timestamp >= gGourceSettings.start_timestamp) {
                    clog->bufferCommit(commit);
                    break;
                }
            }
        }

    } catch(SeekLogException& exception) {
        error = "unable to read log file";
    } catch(SDLAppException& exception) {
        error = exception.what();
    }

    if(!clog && error.empty()) {
        if(boost::filesystem::is_directory(logfile)) {
            if(!log_format.empty()) {
                
                if(gGourceSettings.start_timestamp || gGourceSettings.stop_timestamp) {
                    error = "failed to generate log file for the specified time period";
                } else {
                    error = "failed to generate log file";
                }
#ifdef _WIN32
            // no error - should trigger help message
            } else if(gGourceSettings.default_path && boost::filesystem::exists("./gource.exe")) {
                error = "";
#endif
            } else {
                error = "directory not supported";
            }
        } else {
            error = "unsupported log format (you may need to regenerate your log file)";
        }
    }

    logmill_thread_state = clog ? LOGMILL_STATE_SUCCESS : LOGMILL_STATE_FAILURE;
}

void RLogMill::abort() {
    if(!thread) return;

    // TODO: make abort nicer by notifying the log process
    //       we want to shutdown
    SDL_WaitThread(thread, 0);
    
    thread = 0;
}

bool RLogMill::isFinished() {
    return logmill_thread_state > LOGMILL_STATE_FETCHING;
}

int RLogMill::getStatus() {
    return logmill_thread_state;
}

std::string RLogMill::getError() {
    return error;
}


RCommitLog* RLogMill::getLog() {

    if(thread != 0) {
        SDL_WaitThread(thread, 0);
        thread = 0;        
    }
    
    return clog;
}

bool RLogMill::findRepository(boost::filesystem::path& dir, std::string& log_format) {

    dir = canonical(dir);

    //fprintf(stderr, "find repository from initial path: %s\n", dir.string().c_str());

    while(is_directory(dir)) {

             if(is_directory(dir / ".git") || is_regular_file(dir / ".git")) log_format = "git";
        else if(is_directory(dir / ".hg"))  log_format = "hg";
        else if(is_directory(dir / ".bzr")) log_format = "bzr";
        else if(is_directory(dir / ".svn")) log_format = "svn";

        if(!log_format.empty()) {
            //fprintf(stderr, "found '%s' repository at: %s\n", log_format.c_str(), dir.string().c_str());
            return true;
        }

        if(!dir.has_parent_path()) return false;

        dir = dir.parent_path();
    }

    return false;
}


RCommitLog* RLogMill::fetchMergedLog(std::string& log_format) {
    std::vector<MergeSource> sources;
    std::priority_queue<MergeItem, std::vector<MergeItem>, MergeItemCompare> pending_commits;
    std::map<std::string, int> seen_labels;
    size_t sequence = 0;

    if(!createMergedTempFile(merged_logfile)) {
        error = "failed to create merged log file";
        return 0;
    }

    std::ofstream merged_out(merged_logfile.c_str());
    if(!merged_out.is_open()) {
        error = "failed to write merged log file";
        return 0;
    }

    for(size_t i=0; i<gGourceSettings.paths.size(); i++) {
        std::string source_path = gGourceSettings.paths[i];
        std::string source_format = log_format;
        std::string resolved_path = source_path;

        RCommitLog* source_log = fetchLog(source_path, source_format, &resolved_path);
        if(!source_log) {
            if(error.empty()) {
                error = str(boost::format("failed to open '%s'") % source_path);
            }

            for(size_t j=0; j<sources.size(); j++) {
                delete sources[j].log;
                sources[j].log = 0;
            }

            merged_out.close();
            return 0;
        }

        MergeSource source;
        source.label = repoLabelForPath(resolved_path, seen_labels);
        source.resolved_path = resolved_path;
        source.log = source_log;

        if(readNextCommit(source.log, source.commit)) {
            pending_commits.push(MergeItem{source.commit.timestamp, source.label, source.commit.username, sources.size(), sequence++});
        }

        sources.push_back(source);
    }

    while(!pending_commits.empty()) {
        MergeItem item = pending_commits.top();
        pending_commits.pop();

        MergeSource& source = sources[item.source_index];
        const RCommit& commit = source.commit;

        for(std::list<RCommitFile>::const_iterator it = commit.files.begin(); it != commit.files.end(); it++) {
            const RCommitFile& cf = *it;
            std::string merged_path = prefixRepoPath(source.label, cf.filename);
            std::string colour = colourToHex(cf.colour);

            merged_out << (long long int) commit.timestamp
                       << "|" << commit.username
                       << "|" << cf.action
                       << "|" << merged_path
                       << "|#" << colour
                       << std::endl;
        }

        if(readNextCommit(source.log, source.commit)) {
            pending_commits.push(MergeItem{source.commit.timestamp, source.label, source.commit.username, item.source_index, sequence++});
        }
    }

    merged_out.close();

    for(size_t i=0; i<sources.size(); i++) {
        delete sources[i].log;
        sources[i].log = 0;
    }

    RCommitLog* merged_log = new CustomLog(merged_logfile);
    if(merged_log->checkFormat()) return merged_log;

    delete merged_log;
    return 0;
}

RCommitLog* RLogMill::fetchLog(std::string& log_format) {
    return fetchLog(logfile, log_format);
}

RCommitLog* RLogMill::fetchLog(const std::string& path, std::string& log_format, std::string* resolved_path) {

    RCommitLog* clog = 0;
    std::string source_path = path;

    //if the log format is not specified and 'logfile' is a directory, recursively look for a version control repository.
    //this method allows for something strange like someone who having an svn repository inside a git repository
    //(in which case it would pick the svn directory as it would encounter that first)

    if(log_format.empty() && source_path != "-") {

        try {
            boost::filesystem::path repo_path(source_path);

            if(is_directory(repo_path)) {
                if(findRepository(repo_path, log_format)) {
                    source_path = repo_path.string();
                }
            }
        } catch(boost::filesystem::filesystem_error& error) {
        }
    }

    if(resolved_path != 0) {
        *resolved_path = source_path;
    }

    //we've been told what format to use
    if(log_format.size() > 0) {
        debugLog("log-format = %s", log_format.c_str());

        if(log_format == "git") {
            clog = new GitCommitLog(source_path);
            if(clog->checkFormat()) return clog;
            delete clog;

            clog = new GitRawCommitLog(source_path);
            if(clog->checkFormat()) return clog;
            delete clog;
        }

        if(log_format == "hg") {
            clog = new MercurialLog(source_path);
            if(clog->checkFormat()) return clog;
            delete clog;
        }

        if(log_format == "bzr") {
            clog = new BazaarLog(source_path);
            if(clog->checkFormat()) return clog;
            delete clog;
        }

        if(log_format == "cvs") {
            clog = new CVSEXPCommitLog(source_path);
            if(clog->checkFormat()) return clog;
            delete clog;
        }

        if(log_format == "custom") {
            clog = new CustomLog(source_path);
            if(clog->checkFormat()) return clog;
            delete clog;
        }

        if(log_format == "apache") {
            clog = new ApacheCombinedLog(source_path);
            if(clog->checkFormat()) return clog;
            delete clog;
        }

        if(log_format == "svn") {
            clog = new SVNCommitLog(source_path);
            if(clog->checkFormat()) return clog;
            delete clog;
        }

        if(log_format == "cvs2cl") {
            clog = new CVS2CLCommitLog(source_path);
            if(clog->checkFormat()) return clog;
            delete clog;
        }

        return 0;
    }

    // try different formats until one works

    //git
    debugLog("trying git...");
    clog = new GitCommitLog(source_path);
    if(clog->checkFormat()) return clog;

    delete clog;

    //mercurial
    debugLog("trying mercurial...");
    clog = new MercurialLog(source_path);
    if(clog->checkFormat()) return clog;

    delete clog;

    //bzr
    debugLog("trying bzr...");
    clog = new BazaarLog(source_path);
    if(clog->checkFormat()) return clog;

    delete clog;

    //git raw
    debugLog("trying git raw...");
    clog = new GitRawCommitLog(source_path);
    if(clog->checkFormat()) return clog;

    delete clog;

    //cvs exp
    debugLog("trying cvs-exp...");
    clog = new CVSEXPCommitLog(source_path);
    if(clog->checkFormat()) return clog;

    delete clog;

    //svn
    debugLog("trying svn...");
    clog = new SVNCommitLog(source_path);
    if(clog->checkFormat()) return clog;

    delete clog;

    //cvs2cl
    debugLog("trying cvs2cl...");
    clog = new CVS2CLCommitLog(source_path);
    if(clog->checkFormat()) return clog;

    delete clog;

    //custom
    debugLog("trying custom...");
    clog = new CustomLog(source_path);
    if(clog->checkFormat()) return clog;

    delete clog;

    //apache
    debugLog("trying apache combined...");
    clog = new ApacheCombinedLog(source_path);
    if(clog->checkFormat()) return clog;

    delete clog;

    return 0;
}
