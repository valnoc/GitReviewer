#!/bin/bash

if [[ -z "$1" || -z "$2" ]]; then
    echo ""
    echo ". reviewer.sh <main_branch> <path_to_project_folder>"
    echo ""
    echo "main_branch = your current branch will be merged into main_branch after code review"
    echo "path_to_project_folder = path to project folder"
    echo ""
    echo "Example:"
    echo ". reviewer.sh develop ~/Documents/my_project"
    echo ""
    return
fi

pushd $2

CURRENT_BRANCH=`git branch | grep \* | cut -d ' ' -f2`
MAIN_BRANCH=$1

green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

echo "${yellow}Stash current${reset}"
git stash
echo ""

echo "${yellow}Pull $MAIN_BRANCH${reset}"
git checkout $MAIN_BRANCH
git pull
echo ""

echo "${yellow}Merge $MAIN_BRANCH into $CURRENT_BRANCH${reset}"
git checkout $CURRENT_BRANCH
git merge $MAIN_BRANCH
git push
echo ""

echo "${yellow}Soft reset to $MAIN_BRANCH to get modified files${reset}"
git reset --soft $MAIN_BRANCH
MODIFIED_FILES=`git diff --name-only --cached`
git pull
echo ""
echo "${yellow}Files${reset}"
echo "${MODIFIED_FILES[@]}"
echo ""

echo "${yellow}Calculate code ownership of modified parts${reset}"
git checkout $MAIN_BRANCH

RESULT=() #string "author=count"
for FILE_PATH in $MODIFIED_FILES; do
    #echo $FILE_PATH
    #get authors of this file
    UNIQ_AUTHORS=( $(git blame $FILE_PATH --line-porcelain | grep "^author " | sort | sed 's/author //g' | tr ' ' '_' | uniq -c | sed 's/ *\([0-9]*\) \(.*\)/\2=\1/') )

    for AUTHOR in ${UNIQ_AUTHORS[@]}; do
        AUTHOR_INFO_ARR=( $(echo $AUTHOR | tr "=" " ") )
        AUTHOR_NAME=${AUTHOR_INFO_ARR[0]}
        AUTHOR_COUNT=${AUTHOR_INFO_ARR[1]}
        #echo "Person="$AUTHOR_NAME" Count="$AUTHOR_COUNT

        # no hash arrays in bash 3.2, so have to loop through the ordinary array
        # search author in RESULT and set new count of lines
        INDEX=-1
        for i in "${!RESULT[@]}"; do 
            RES_AUTHOR_INFO_ARR=( $(echo ${RESULT[$i]} | tr "=" " ") )
            RES_AUTHOR_NAME=${RES_AUTHOR_INFO_ARR[0]}
            RES_AUTHOR_COUNT=${RES_AUTHOR_INFO_ARR[1]}
            #echo $RES_AUTHOR_NAME

            if [[ $RES_AUTHOR_NAME == $AUTHOR_NAME ]]; then
                INDEX=i
                #echo "found"
                RESULT[$i]="$AUTHOR_NAME=$(($AUTHOR_COUNT + $RES_AUTHOR_COUNT))"
                break
            fi
        done

        if [[ $INDEX -lt 0 ]]; then
            #echo "not Found"
            RESULT[${#RESULT[@]}]=$AUTHOR
        fi
    done
    #echo ""

    #echo "RESULT For now ${RESULT[@]}"
    #echo ""
done

TOTAL_LINES=0
for i in "${!RESULT[@]}"; do 
    AUTHOR_INFO_ARR=( $(echo ${RESULT[$i]} | tr "=" " ") )
    AUTHOR_COUNT=${AUTHOR_INFO_ARR[1]}
    
    TOTAL_LINES=$(($TOTAL_LINES + $AUTHOR_COUNT))
done

for i in "${!RESULT[@]}"; do 
    AUTHOR_INFO_ARR=( $(echo ${RESULT[$i]} | tr "=" " ") )
    AUTHOR_NAME=${AUTHOR_INFO_ARR[0]}
    AUTHOR_COUNT=${AUTHOR_INFO_ARR[1]}

    AUTHOR_PERCENT=$(echo "scale=5; $AUTHOR_COUNT / $TOTAL_LINES * 100" | bc)
    AUTHOR_PERCENT=$(printf '%04.1f' $AUTHOR_PERCENT)

    RESULT[$i]="$AUTHOR_PERCENT=$AUTHOR_NAME=$AUTHOR_COUNT"
done

RESULT=( $(printf '%s\n' "${RESULT[@]}" | sort -r | head -n 5) )

echo ""
echo "${yellow}TOTAL_LINES = $TOTAL_LINES${reset}"
for i in "${!RESULT[@]}"; do 
    AUTHOR_INFO_ARR=( $(echo ${RESULT[$i]} | tr "=" " ") )
    AUTHOR_PERCENT=${AUTHOR_INFO_ARR[0]}
    AUTHOR_NAME=${AUTHOR_INFO_ARR[1]}
    AUTHOR_COUNT=${AUTHOR_INFO_ARR[2]}    
    echo "$AUTHOR_PERCENT% ${green}$AUTHOR_NAME${reset}, $AUTHOR_COUNT lines"
done
echo ""

echo "${yellow}Return to $CURRENT_BRANCH${reset}"
git checkout $CURRENT_BRANCH
echo ""

popd