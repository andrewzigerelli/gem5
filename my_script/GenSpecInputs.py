#!/usr/bin/python3
import os
import sys
import subprocess
import re
import pickle
import time


def main():
    # get spec2017 path
    try:
        specPath = sys.argv[1]
    except:
        errMsg = "Need to give Spec2017 path as argument! "
        errMsg += "e.g. \n python GenSpecInputs.py /opt/spec2017"
        raise ValueError(errMsg)

    try:
        runSuffix = sys.argv[2]
    except:
        errMsg = "Need to give run dir numbers as argument. "
        errMsg += "e.g. \n python GenSpecInputs.py /opt/spec2017 0001"
        raise ValueError(errMsg)

    # add benchspec/CPU
    # call join twice to be OS agnostic
    benchesPath = os.path.join(specPath, "benchspec")
    benchesPath = os.path.join(benchesPath, "CPU")

    if os.path.isdir(benchesPath):
        # we can set specinvoke path
        specinvokePath = os.path.join(specPath, "bin")
        specinvokeBin = os.path.join(specinvokePath, "specinvoke")
        print(benchesPath)
    else:
        raise ValueError("Spec2017 benchmark path not found")

    # get benchmarks
    benches={}
    dirs = [
        d for d in os.listdir(benchesPath)
        if os.path.isdir(os.path.join(benchesPath, d))
    ]
    benches = {d:os.path.join(benchesPath,d) for d in dirs}

    # make readfile directory and command file
    specFile = open("spec_cmds.txt", "w")
    try:
        os.mkdir("readfiles")
    except FileExistsError:
        pass
    cwd = os.getcwd()
    readfileDir=os.path.join(cwd,"readfiles")


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
        parseCmd(substring, readfileDir, bench)
        specFile.write(substring+"\n")

    # write to
    specFile.close()

def parseCmd(cmd, readfileDir, bench):
    lines = cmd.splitlines()
    i = 0
    while len(lines) != 0:
        del lines[0]
        command = lines[0] + ";" + lines[1] + ";m5 exit;"
        del lines[0:2]
        readfile=os.path.join(readfileDir,bench + "_readfile_" + str(i))
        with open(readfile,"w") as f:
            f.write(command)
        i+=1



def save_obj(obj, name):
    with open(name + '.pkl', 'wb') as f:
        pickle.dump(obj, f, pickle.HIGHEST_PROTOCOL)

def load_obj(name):
    with open(name + '.pkl', 'rb') as f:
        return pickle.load(f)


if __name__ == "__main__":
    main()
