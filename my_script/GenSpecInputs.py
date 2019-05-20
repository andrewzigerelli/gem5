#!/usr/bin/python3
import os
import sys
import subprocess
import re
import pickle
import time

# readfile for FS mode is straightforward: just command to be run in gem5
# for SE mode, it's 4 lines
#  0:  BENCH_DIR
#  1:  --cmd and --options lines
#  2:  output file name
#  3:  stderr file name

def main():
    # get spec2017 path
    try:
        specPath = sys.argv[1]
    except:
        errMsg = "Need to give Spec2017 path as argument! "
        errMsg += "e.g. \n python GenSpecInputs.py /opt/spec2017 0001 se"
        raise ValueError(errMsg)

    try:
        runSuffix = sys.argv[2]
    except:
        errMsg = "Need to give run dir numbers as argument. "
        errMsg += "e.g. \n python GenSpecInputs.py /opt/spec2017 0001 se"
        raise ValueError(errMsg)

    try:
        mode = sys.argv[3]
        mode = mode.rstrip()
    except:
        errMsg = "Need to give mode, either se or fs"
        errMsg += "e.g. \n python GenSpecInputs.py /opt/spec2017 0001 se"
        raise ValueError(errMsg)

    # add benchspec/CPU
    # call join twice to be OS agnostic
    benchesPath = os.path.join(specPath, "benchspec")
    benchesPath = os.path.join(benchesPath, "CPU")

    if os.path.isdir(benchesPath):
        # we can set specinvoke path
        specinvokePath = os.path.join(specPath, "bin")
        specinvokeBin = os.path.join(specinvokePath, "specinvoke")
    else:
        raise ValueError("Spec2017 benchmark path not found")

    # get benchmarks
    benches = {}
    dirs = [
        d for d in os.listdir(benchesPath)
        if os.path.isdir(os.path.join(benchesPath, d))
    ]
    benches = {d: os.path.join(benchesPath, d) for d in dirs}

    # make readfile directory and command file
    specFile = open("spec_cmds.txt", "w")
    try:
        os.mkdir("readfiles")
    except FileExistsError:
        pass
    cwd = os.getcwd()

    if mode == "fs":
        readfileDir = os.path.join(cwd, "readfiles")
    elif mode == "se":
        readfileDir = os.path.join(cwd, "se_readfiles")
    else:
        errMsg = "Need to give mode, either se or fs"
        errMsg += "e.g. \n python GenSpecInputs.py /opt/spec2017 0001 se"
        raise ValueError(errMsg)

    # get and write commandline
    for bench, benchdir in benches.items():
        # check if there are runfolders
        runFolder = os.path.join(benchdir, "run")
        if not os.path.isdir(runFolder):
            print("Warning: %s doesn't exist" % runFolder)
            continue
        folders = [
            os.path.join(runFolder, f) for f in os.listdir(runFolder)
            if os.path.isdir(os.path.join(runFolder, f))
        ]
        # run folders end in name.xxxx, where xxxx is number
        regex = "." + runSuffix + "$"
        regex = re.compile(regex)
        folder = ''.join(filter(regex.search, folders))
        speccmds = os.path.join(folder, 'speccmds.cmd')
        if not os.path.exists(speccmds):
            print("Warning: %s doesn't exist" % speccmds)
            continue

        # call specinvoke
        speccmd = [specinvokeBin, "-nn", speccmds]
        speccmd = subprocess.Popen(speccmd, stdout=subprocess.PIPE)
        spec_out = speccmd.communicate()[0]
        spec_out = spec_out.decode(sys.stdin.encoding)
        start = spec_out.find("# Starting run for copy")
        last = spec_out.find("specinvoke exit")
        substring = spec_out[start:last]
        parseCmd(substring, readfileDir, bench, mode)
        specFile.write(substring+"\n")

    # write to
    specFile.close()


def parseCmd(cmd, readfileDir, bench, mode):
    lines = cmd.splitlines()

    # regex for parsing se mode
    cmdRegex = "^([^><]+?)?(< .+?)?(> .+?)?(2>> .+)$"
    cmdRegex = re.compile(cmdRegex)

    textRegex = "\s+.*"
    textRegex = re.compile(textRegex)

    i = 0
    while len(lines) != 0:
        del lines[0]
        if mode == "fs":
            command = lines[0] + ";" + lines[1] + ";m5 exit;"
        else:
            # we must create command by parsing text
            runFolder = lines[0][3:]
            binaryNamePosEnd = lines[1].find(' ')
            binary = lines[1][:binaryNamePosEnd]
            cmd = os.path.basename(os.path.normpath(binary))
            rest = lines[1][binaryNamePosEnd + 1:]

            command = runFolder + "\n" + "--cmd=" + cmd

            # parse input options
            result = cmdRegex.search(rest)
            result = result.groups()

            options = result[0]
            if options:
                options = options.rstrip()
                command = command + ' --options="' + options + '"'

            stdin = result[1]
            if stdin:
                stdin = stdin.rstrip()
                text = textRegex.search(stdin)
                text = text.group(0).lstrip()
                command = command + " --input=" + text + "\n"
            else:
                command = command + "\n"

            stdout = result[2]
            if stdout:
                stdout = stdout.rstrip()
                text = textRegex.search(stdout)
                text = text.group(0).lstrip()
                command = command + text + "\n"
            else:
                command = command + "\n"

            stderr = result[3]
            if stderr:
                stderr = stderr.rstrip()
                text = textRegex.search(stderr)
                text = text.group(0).lstrip()
                command = command + text + "\n"
            else:
                command = command + "\n"
            
        del lines[0:2]
        readfile = os.path.join(readfileDir, bench + "_readfile_" + str(i))
        with open(readfile, "w") as f:
            f.write(command)
        i += 1


def save_obj(obj, name):
    with open(name + '.pkl', 'wb') as f:
        pickle.dump(obj, f, pickle.HIGHEST_PROTOCOL)


def load_obj(name):
    with open(name + '.pkl', 'rb') as f:
        return pickle.load(f)


if __name__ == "__main__":
    main()
