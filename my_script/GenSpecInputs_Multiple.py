#!/usr/bin/python3
import os
import sys
import subprocess
import re
from itertools import combinations


def main():
    # parse args
    try:
        mode = sys.argv[1]
        mode = mode.rstrip()
    except:
        errMsg = "Need to give mode, either se or fs "
        errMsg += "e.g. \n python GenSpecInputs_Multiple.py se 2"
        raise ValueError(errMsg)

    try:
        num_combo = sys.argv[2]
        num_combo = int(num_combo.rstrip())
    except:
        errMsg = "Need to give num_combo arg as an int"
        errMsg += "e.g. \n python GenSpecInputs_Multiple.py se 2"
        raise ValueError(errMsg)

    # load environment variable and create readfiles path
    gem5_path = os.environ['GEM5_PATH']
    myscript_path = os.path.join(gem5_path, 'my_script')

    # get readfiles path
    if mode == "fs":
        readfile_path = os.path.join(myscript_path, 'readfiles')
    elif mode == "se":
        readfile_path = os.path.join(myscript_path, 'se_readfiles')
    else:
        errMsg = "Need to give mode, either se or fs "
        errMsg += "e.g. \n python GenSpecInputs_Multiple.py se"
        raise ValueError(errMsg)

    # get existing readfiles, only run 0 and not speed benchmarks
    readfiles = {d: os.path.join(readfile_path, d) for d in
                 os.listdir(readfile_path) if d[-1] == "0" and
                 d.find("_s") == -1 and d.find("_is") == -1 and d.find("_fs")
                 == -1}

    # create unique combinations of readfiles
    readfiles_combo = combinations(readfiles, num_combo)
    for combo in readfiles_combo:
        createReadfile(combo, readfiles, readfile_path, mode)


def createReadfile(combo, readfiles, readfile_path, mode):
    # for now, just assume fs mode
    if mode != "fs":
        errMsg = "As of now, only fs mode supported"
        raise ValueError(errMsg)

    combo_name = ""
    cmds = ""
    for bench in combo:
        # add string to combo_name
        underscore_loc = bench.find("_")
        combo_name = combo_name + bench[:underscore_loc+1]

        # get cmd from existing readfile, remove m5 exit, append &;
        bench_readfile = readfiles[bench]
        with open(bench_readfile, 'r') as readfile:
            cmd = readfile.read().replace(';m5 exit;', ' &;')
            cmds += cmd

    # finish combo name
    combo_name = combo_name + "readfile"
    # remove last &, add m5 exit
    cmds = cmds.strip(' &;')
    cmds += ";m5 exit;"

    # write to new readfile
    new_readfile = os.path.join(readfile_path, combo_name)
    with open(new_readfile, "w") as f:
        f.write(cmds)

    # regex for parsing se mode
    # cmdRegex = "^([^><]+?)?(< .+?)?(> .+?)?(2>> .+)$"
    # cmdRegex = re.compile(cmdRegex)

    # textRegex = "\s+.*"
    # textRegex = re.compile(textRegex)

    # i = 0
    # while len(lines) != 0:
    #     del lines[0]
    #     if mode == "fs":
    #         command = lines[0] + ";" + lines[1] + ";m5 exit;"
    #     else:
    #         # we must create command by parsing text
    #         runFolder = lines[0][3:]
    #         binaryNamePosEnd = lines[1].find(' ')
    #         binary = lines[1][:binaryNamePosEnd]
    #         cmd = os.path.basename(os.path.normpath(binary))
    #         rest = lines[1][binaryNamePosEnd + 1:]

    #         command = runFolder + "\n" + "--cmd=" + cmd

    #         # parse input options
    #         result = cmdRegex.search(rest)
    #         result = result.groups()

    #         options = result[0]
    #         if options:
    #             options = options.rstrip()
    #             command = command + ' --options="' + options + '"'

    #         stdin = result[1]
    #         if stdin:
    #             stdin = stdin.rstrip()
    #             text = textRegex.search(stdin)
    #             text = text.group(0).lstrip()
    #             command = command + " --input=" + text + "\n"
    #         else:
    #             command = command + "\n"

    #         stdout = result[2]
    #         if stdout:
    #             stdout = stdout.rstrip()
    #             text = textRegex.search(stdout)
    #             text = text.group(0).lstrip()
    #             command = command + text + "\n"
    #         else:
    #             command = command + "\n"

    #         stderr = result[3]
    #         if stderr:
    #             stderr = stderr.rstrip()
    #             text = textRegex.search(stderr)
    #             text = text.group(0).lstrip()
    #             command = command + text + "\n"
    #         else:
    #             command = command + "\n"

    #     del lines[0:2]
    #     readfile = os.path.join(readfileDir, bench + "_readfile_" + str(i))
    #     with open(readfile, "w") as f:
    #         f.write(command)
    #     i += 1


if __name__ == "__main__":
    main()
