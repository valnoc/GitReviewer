# GitReviewer
A script to get the preferable reviewer for your task depending on code ownership.

When you use ```git flow``` or smth similar, you make a new branch for each issue you solve. 
After solving the problem you either merge changes into ```develop``` (covering new code with feature toggle) or leave your branch to be merged by a reviewer.
Your also change issue status (in Redmine, Jira, etc.) to the one indicating "waiting for review" status.

Use this script if don't use any system of a preferable reviewer autodetection connected with your issue tracker.

## MAN
. reviewer.sh <main_branch> <path_to_project_folder>

main_branch = your current branch will be merged into main_branch after code review

path_to_project_folder = path to project folder

Example:
. reviewer.sh develop ~/Documents/my_project

## Under the hood
This script
- gets the actual state of branches
- makes ```soft reset``` to the ```main branch```
- gets a list of modified files
- git blames authors of this files
- calculates the percentage of the code ownership by authors

## Output
The script logs all the steps, so you can monitor what is going on. There are also commented ```echo```'s for debug needs. Uncomment them if you want more information about the steps.

Look for the green info at the end of the output. It contains info like:
```
TOTAL_LINES = 1856
45.1% Author_1, 837 lines
24.4% Author_2, 452 lines
18.3% Author_3, 339 lines
12.0% Author_4, 223 lines
00.3% Author_5, 5 lines
```

This list contains top 5 authors.

## License

GitReviewer is available under MIT License.
