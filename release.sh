#!/bin/bash

BGreen='\033[1;32m'
Default='\033[0;m'

podName=""
version=""
podspecFilePath=""
homepage=""
httpsRepo=""
oldVersion=""
confirmed="n"

getPodInfo() {

    for file in ./*
    do
        if test -f $file
        then
            if [[ $file == *".podspec"* ]]; then
                filename=`basename $file`
                podName=${filename%.podspec*}
                podspecFilePath="./${podName}.podspec"
            fi
        fi
    done

    while read line; do    
        line=${line//[[:blank:]]/}
        if [[ $line == *".homepage="* ]]; then
            homepage=${line##*='"'}
            homepage=${homepage%'"'}
        fi
        if [[ $line == *".source="* ]]; then
            httpsRepo=${line##*git=>'"'}
            httpsRepo=${httpsRepo%'"'*}
        fi
        # 截取旧版本号
        if [[ $line == *"s.version"*"="* ]]; then
            oldVersion=${line##*=}
            oldVersion=${oldVersion#*\"}
            oldVersion=${oldVersion%\"}
            oldVersion=${oldVersion#*\'}
            oldVersion=${oldVersion%\'}
        fi
    done < $podspecFilePath
}

getVersion() {
    read -p "Enter New Version: " version

    if test -z "$version"; then
        getVersion
    fi
}

updateVersion() {

    # update .podspec file
	while read line; do
        if [[ $line == *"s.version"*"="* ]]; then
            newLine=${line/$oldVersion/$version}
            sed -i '' "s#$line#$newLine#" "$podspecFilePath"
        fi
    done < $podspecFilePath

    # update README.md file
    while read line; do
        if [[ $line == *"pod"*"${oldVersion}"* ]]; then
            newLine=${line/$oldVersion/$version}
            sed -i '' "s#$line#$newLine#" "./README.md"
        fi
        if [[ $line == *"github"*"${podName}"*"${oldVersion}"* ]]; then
            newLine=${line/$oldVersion/$version}
            sed -i '' "s#${line}#${newLine}#" "./README.md"
        fi
    done < "./README.md"

    # update Xcode project
    updateProjectVersion --version=$version --target=$podName
    # ./update_version.sh --version=$version --target=$podName
}

getInfomation() {
    getVersion

    echo -e "\n${Default}================================================"
    echo -e "  Pod Name      :  ${BGreen}${podName}${Default}"
    echo -e "  Version       :  ${BGreen}${version}${Default}"
    echo -e "  HTTPS Repo    :  ${BGreen}${httpsRepo}${Default}"
    echo -e "  Home Page URL :  ${BGreen}${homepage}${Default}"
    echo -e "================================================\n"
}

########### Compare newVersion and oldVersion ###############
compareVersion() {
    ## @file version_compare
    ## Compare [semantic] versions in Bash, comparable to PHP's version_compare function.
    # ------------------------------------------------------------------
    ## @author Mark Carver <mark.carver@me.com>
    ## @copyright MIT
    ## @version 1.0.0
    ## @see http://php.net/manual/en/function.version-compare.php

    APP_NAME=$(basename ${0})
    APP_VERSION="1.0.0"

    # Version compare 
    function version_compare () {
      # Default to a failed comparison result.
      local -i result=1;

      # Ensure there are two versions to compare.
      [ $# -lt 2 ] || [ -z "${1}" ] || [ -z "${2}" ] && echo "${FUNCNAME[0]} requires a minimum of two arguments to compare versions." &>/dev/stderr && return ${result}

      # Determine the operation to perform, if any.
      local op="${3}"
      
      # Convert passed versions into values for comparison.
      local v1=$(version_compare_convert ${1})
      local v2=$(version_compare_convert ${2})
      
      # Immediately return when comparing version equality (which doesn't require sorting).
      if [ -z "${op}" ]; then
        [ "${v1}" == "${v2}" ] && echo 0 && return;
      else
        if [ "${op}" == "!=" ] || [ "${op}" == "<>" ] || [ "${op}" == "ne" ]; then
          if [ "${v1}" != "${v2}" ]; then let result=0; fi;
          return ${result};
        elif [ "${op}" == "=" ] || [ "${op}" == "==" ] || [ "${op}" == "eq" ]; then
          if [ "${v1}" == "${v2}" ]; then let result=0; fi;
          return ${result};
        elif [ "${op}" == "le" ] || [ "${op}" == "<=" ] || [ "${op}" == "ge" ] || [ "${op}" == ">=" ] && [ "${v1}" == "${v2}" ]; then
          if [ "${v1}" == "${v2}" ]; then let result=0; fi;
          return ${result};
        fi
      fi
      
      # If we get to this point, the versions should be different.
      # Immediately return if they're the same.
      [ "${v1}" == "${v2}" ] && return ${result}
      
      local sort='sort'
      
      # If only one version has a pre-release label, reverse sorting so
      # the version without one can take precedence.
      [[ "${v1}" == *"-"* ]] && [[ "${v2}" != *"-"* ]] || [[ "${v2}" == *"-"* ]] && [[ "${v1}" != *"-"* ]] && sort="${sort} -r"

      # Sort the versions.
      local -a sorted=($(printf "%s\n%s" "${v1}" "${v2}" | ${sort}))
      
      # No operator passed, indicate which direction the comparison leans.
      if [ -z "${op}" ]; then
        if [ "${v1}" == "${sorted[0]}" ]; then echo -1; else echo 1; fi
        return
      fi
      
      case "${op}" in
        "<" | "lt" | "<=" | "le") if [ "${v1}" == "${sorted[0]}" ]; then let result=0; fi;;
        ">" | "gt" | ">=" | "ge") if [ "${v1}" == "${sorted[1]}" ]; then let result=0; fi;;
      esac

      return ${result}
    }

    # Converts a version string to an integer that is used for comparison purposes.
    function version_compare_convert () {
      local version="${@}"

      # Remove any build meta information as it should not be used per semver spec.
      version="${version%+*}"

      # Extract any pre-release label.
      local prerelease
      [[ "${version}" = *"-"* ]] && prerelease=${version##*-}
      [ -n "${prerelease}" ] && prerelease="-${prerelease}"
      
      version="${version%%-*}"

      # Separate version (minus pre-release label) into an array using periods as the separator.
      local OLDIFS=${IFS} && local IFS=. && version=(${version%-*}) && IFS=${OLDIFS}
      
      # Unfortunately, we must use sed to strip of leading zeros here.
      local major=$(echo ${version[0]:=0} | sed 's/^0*//')
      local minor=$(echo ${version[1]:=0} | sed 's/^0*//')
      local patch=$(echo ${version[2]:=0} | sed 's/^0*//')
      local build=$(echo ${version[3]:=0} | sed 's/^0*//')

      # Combine the version parts and pad everything with zeros, except major.
      printf "%s%04d%04d%04d%s\n" "${major}" "${minor}" "${patch}" "${build}" "${prerelease}"
    }

    # Color Support
    # See: http://unix.stackexchange.com/a/10065
    if test -t 1; then
      ncolors=$(tput colors)
      if test -n "$ncolors" && test $ncolors -ge 8; then
        bold="$(tput bold)" && underline="$(tput smul)" && standout="$(tput smso)" && normal="$(tput sgr0)"
        black="$(tput setaf 0)" && red="$(tput setaf 1)" && green="$(tput setaf 2)" && yellow="$(tput setaf 3)"
        blue="$(tput setaf 4)" && magenta="$(tput setaf 5)" && cyan="$(tput setaf 6)" && white="$(tput setaf 7)"
      fi
    fi

    function version_compare_usage {
      echo "${bold}${APP_NAME} (${APP_VERSION})${normal}"
      echo "Compare [semantic] versions in Bash, comparable to PHP's version_compare function."
      echo
      echo "${bold}Usage:${normal}"
      echo "    ${APP_NAME} [-hV] ${cyan}<version1> <version2>${normal} [${cyan}<operator>${normal}]"
      echo
      echo "${bold}Required arguments:${normal}"
      echo "    - ${cyan}<version1>${normal}: First version number to compare."
      echo "    - ${cyan}<version2>${normal}: Second version number to compare."
      echo
      echo "${bold}Optional arguments:${normal}"
      echo "    - ${cyan}<operator>${normal}: When this argument is provided, it will test for a particular"
      echo "      relationship. This argument is case-sensitive, values should be lowercase."
      echo "      Possible operators are:"
      echo "          ${bold}=, ==, eq${normal}    (equal)"
      echo "          ${bold}>, gt${normal}        (greater than)"
      echo "          ${bold}>=, ge${normal}       (greater than or equal)"
      echo "          ${bold}<, lt${normal}        (less than)"
      echo "          ${bold}<=, le${normal}       (less than or equal)"
      echo "          ${bold}!=, <>, ne${normal}   (not equal)"
      echo
      echo "${bold}Return Value:${normal}"
      echo "    There are two distinct operation modes for ${APP_NAME}. It's solely based"
      echo "    on whether or not the ${cyan}<operator>${normal} argument was provided:"
      echo
      echo "    - When ${cyan}<operator>${normal} IS provided, ${APP_NAME} will return either a 0 or 1"
      echo "      exit code (no output printed to /dev/stdout) based on the result of the ${cyan}<operator>${normal}"
      echo "      relationship between the versions. This is particularly useful in cases where"
      echo "      testing versions can, historically, be quite cumbersome:"
      echo
      echo "          ${magenta}! ${APP_NAME} \${version1} \${version2} \">\" && echo \"You have not met the minimum version requirements.\" && exit 1${normal}"
      echo
      echo "      You can, of course, opt for the more traditional/verbose conditional"
      echo "      block in that suites your fancy:"
      echo
      echo "          ${magenta}${APP_NAME} \${version1} \${version2}"
      echo "          if [ \$? -gt 0 ]; then"
      echo "            echo \"You have not met the minimum version requirements.\""
      echo "            exit 1"
      echo "          fi${normal}"
      echo
      echo "    - When ${cyan}<operator>${normal} is NOT provided, ${APP_NAME} will output (print to /dev/stdout):"
      echo "          -1: ${cyan}<version1>${normal} is lower than ${cyan}<version2>${normal}"
      echo "           0: ${cyan}<version1>${normal} and ${cyan}<version2>${normal} are equal"
      echo "           1: ${cyan}<version2>${normal} is lower than ${cyan}<version1>${normal}"
      echo
      echo "      This mode is primarily only ever helpful when there is a need to determine the"
      echo "      relationship between two versions and provide logic for all three states:"
      echo
      echo "          ${magenta}ret=\$(${APP_NAME} \${version1} \${version2})"
      echo "          if [ \"\${ret}\" == \"-1\" ]; then"
      echo "            # Do some logic here."
      echo "          elif [ \"\${ret}\" == \"0\" ]; then"
      echo "            # Do some logic here."
      echo "          else"
      echo "            # Do some logic here."
      echo "          fi${normal}"
      echo
      echo "    While there are use cases for both modes, it's recommended that you provide an"
      echo "    ${cyan}<operator>${normal} argument to reduce any logic whenever possible."
      echo
      echo "${bold}Options:${normal}"
      echo "  ${bold}-h${normal}  Display this help and exit."
      echo "  ${bold}-V${normal}  Display version information and exit."
}

# Do not continue if sourced.
[[ ${0} != "$BASH_SOURCE" ]] && return

# Process options.
while getopts ":hV" opt; do
    case $opt in
      h) version_compare_usage && exit;;
      V) echo "${APP_VERSION}" && exit;;
      \?|*) echo "${red}${APP_NAME}: illegal option: -- ${OPTARG}${normal}" >&2 && echo && version_compare_usage && exit 64;;
    esac
done
shift $((OPTIND-1)) # Remove parsed options.

# Allow script to be invoked as a CLI "command" by proxying arguments to the internal function.
[ $# -gt 0 ] && version_compare ${@}

}

########### Update Xocde Info.plist ###############
updateProjectVersion() {
    # Link: <https://gist.github.com/jellybeansoup/db7b24fb4c7ed44030f4>
    # ./update-version.sh --version=1.2.9 --build=95 --target=MonkeyKing

    # We use PlistBuddy to handle the Info.plist values. Here we define where it lives.
    plistBuddy="/usr/libexec/PlistBuddy"

    BGreen='\033[1;32m'

    # Parse input variables and update settings.
    for i in "$@"; do
    case $i in
        -h|--help)
        echo "usage: sh version-update.sh [options...]\n"
        echo "Options: (when provided via the CLI, these will override options set within the script itself)"
        echo "    --build=<number>          Apply the given value to the build number (CFBundleVersion) for the project."
        echo "-p, --plist=<path>            Use the specified plist file as the source of truth for version details."
        echo "    --version=<number>        Apply the given value to the marketing version (CFBundleShortVersionString) for the project."
        echo "-x, --xcodeproj=<path>        Use the specified Xcode project file to gather plist names."
        echo "-x, --target=<name>           Use the specified Xcode project target to gather plist names."
        echo "\nFor more detailed information on the use of these variables, see the script source."
        exit 1 
        ;;
        -x=*|--xcodeproj=*)
        xcodeproj="${i#*=}"
        shift
        ;;
        -p=*|--plist=*)
        plist="${i#*=}"
        shift
        ;;
        --target=*)
        specified_target="${i#*=}"
        shift
        ;;
        --build=*)
        specified_build="${i#*=}"
        shift
        ;;
        --version=*)
        specified_version="${i#*=}"
        shift
        ;;
        *)
        ;;
    esac
    done

    # Locate the xcodeproj.
    # If we've specified a xcodeproj above, we'll simply use that instead.
    if [[ -z ${xcodeproj} ]]; then
        xcodeproj=$(find . -depth 1 -name "*.xcodeproj" | sed -e 's/^\.\///g')
    fi

    # Check that the xcodeproj file we've located is valid, and warn if it isn't.
    # This could also indicate an issue with the code used to automatically locate the xcodeproj file.
    # If you're encountering this and the file exists, ensure that ${xcodeproj} contains the correct
    # path, or use the "--xcodeproj" variable to provide an accurate location.
    if [[ ! -f "${xcodeproj}/project.pbxproj" ]]; then
        echo "${BASH_SOURCE}:${LINENO}: error: Could not locate the xcodeproj file \"${xcodeproj}\"."
        exit 1
    else 
        echo "Xcode Project: \"${xcodeproj}\""
    fi

    # Find unique references to Info.plist files in the project
    projectFile="${xcodeproj}/project.pbxproj"
    plists=$(grep "^\s*INFOPLIST_FILE.*$" "${projectFile}" | sed -Ee 's/^[[:space:]]+INFOPLIST_FILE[[:space:]*=[[:space:]]*["]?([^"]+)["]?;$/\1/g' | sort | uniq)

    # Attempt to guess the plist based on the list we have.
    # If we've specified a plist above, we'll simply use that instead.
    if [[ -z ${plist} ]]; then
        while read -r thisPlist; do
            if [[ $thisPlist == *"${specified_target}"* ]]; then
                plist=$thisPlist
            fi
        done <<< "${plists}"
    fi

    # Check that the plist file we've located is valid, and warn if it isn't.
    # This could also indicate an issue with the code used to match plist files in the xcodeproj file.
    # If you're encountering this and the file exists, ensure that ${plists} contains _ONLY_ filenames.
    if [[ ! -f ${plist} ]]; then
        echo "${BASH_SOURCE}:${LINENO}: error: Could not locate the plist file \"${plist}\"."
        exit 1      
    else
        echo "Source Info.plist: \"${plist}\""
    fi

    # Find the current build number in the main Info.plist
    mainBundleVersion=$("${plistBuddy}" -c "Print CFBundleVersion" "${plist}")
    mainBundleShortVersionString=$("${plistBuddy}" -c "Print CFBundleShortVersionString" "${plist}")
    echo "Current project version is ${mainBundleShortVersionString} (${mainBundleVersion})."

    # If the user specified a marketing version (via "--version"), we overwrite the version from the source of truth.
    if [[ ! -z ${specified_version} ]]; then
        mainBundleShortVersionString=${specified_version}
        echo "Applying specified marketing version (${specified_version})..."
    fi

    if [[ ! -z ${specified_build} ]]; then
        mainBundleVersion=${specified_build}
        echo "Applying specified build number (${specified_build})..."
    fi

    # Update all of the Info.plist files we discovered
    while read -r thisPlist; do
        # Find out the current version
        thisBundleVersion=$("${plistBuddy}" -c "Print CFBundleVersion" "${thisPlist}")
        thisBundleShortVersionString=$("${plistBuddy}" -c "Print CFBundleShortVersionString" "${thisPlist}")
        # Update the CFBundleVersion if needed
        if [[ ${thisBundleVersion} != ${mainBundleVersion} ]]; then
            echo -e "${BGreen}Updating \"${thisPlist}\" with build ${mainBundleVersion}..."
            "${plistBuddy}" -c "Set :CFBundleVersion ${mainBundleVersion}" "${thisPlist}"
        fi
        # Update the CFBundleShortVersionString if needed
        if [[ ${thisBundleShortVersionString} != ${mainBundleShortVersionString} ]]; then
            echo -e "${BGreen}Updating \"${thisPlist}\" with marketing version ${mainBundleShortVersionString}..."
            "${plistBuddy}" -c "Set :CFBundleShortVersionString ${mainBundleShortVersionString}" "${thisPlist}"
            git add "${thisPlist}"
        fi
        echo -e "${BGreen}Current \"${thisPlist}\" version is ${mainBundleShortVersionString} (${mainBundleVersion})."
    done <<< "${plist}"
}

########### 开始 ###############

getPodInfo

echo -e "\n"

echo "Current Version: ${oldVersion}"

while [ "$confirmed" != "y" -a "$confirmed" != "Y" ]
do
    if [ "$confirmed" == "n" -o "$confirmed" == "N" ]; then
        getInfomation
    fi
    read -p "confirm? (y/n):" confirmed
done

! compareVersion $version $oldVersion ">" && echo "Invalid version. $version <= $oldVersion" && exit 1

updateVersion

echo ""

echo "--------------------------------------------------------------------------------"

echo ""

git add "${podspecFilePath}"
git add "./README.md"
git commit -m "[$podName] update version $version"
git push

git tag "${version}"
git push --tags

echo ""

echo "--------------------------------------------------------------------------------"
echo "Start pod trunk push \"${podName}.podspec\" --allow-warnings"

pod trunk push "${podName}.podspec" --allow-warnings

echo -e "\n"

say "finished"
echo "finished"
