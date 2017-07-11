# Code for DC - The Rat Hack

This is the Code for DC rats project. We are exploring data on rodent abatement complaints submitted to DC 311. The short-term goal is to visualize historical data on 311 calls and search for simple correlations with potential mechanisms for rat complaints. The long-term goal is to develop a model that can predict clusters of 311 rodent complaints in time and space, as an informative tool for city managers.

## Quick Links
Check out the "rats" channel on the [Code for DC slack!](https://codefordc.org/joinslack)
Access our prototype of the 311 data portal [here](http://dc311portal.codefordc.org/)
Download the 311 data from Dropbox [here](https://www.dropbox.com/sh/4j7q53lltasez3h/AACTJgmlkmKE9zlPp1ndYu9Va?dl=0)
View our open issues on Trello [here](https://trello.com/b/1u5zLyEJ/code-for-dc-rats)

## Getting started with R and the 311 data (for newbies)
We have rolled some starting R code and 311 data into a virtual image that can be accessed using a software called Docker. This allows users to run and modify R code that explores the 2016 311 data without needing to install R and script-dependent R packages.

1. Get started by installing the free Docker Community Edition for your operating system:
* [download for Windows 10 Professional](https://docs.docker.com/docker-for-windows/) ([additional installation instructions](https://docs.docker.com/docker-for-windows/)) 
* [download for Mac](https://www.docker.com/docker-mac) ([additional installation instructions](https://docs.docker.com/docker-for-mac/))
* [follow instructions for installation in Ubuntu](https://docs.docker.com/engine/installation/linux/ubuntu/)

2. Next, run the Docker image for our project from Code for DC's Docker Hub. Open a Terminal or shell and use the following command (Note that you will need to enter your administrator/sudo password into the command line after executing the command):
```
$ sudo docker run -d -p 8787:8787 codefordc2/explore-311-data-in-r
```
If you were unable to pull the Docker image from Docker Hub, try downloading the Docker image for our project, called "RStudio Server Demo.zip" from this [Dropbox folder](https://www.dropbox.com/sh/z25tdp9w0ovb6ug/AAA0nIWUbXEzqmwHo8mRqZTRa?dl=0). Then, build the Docker image with the following command:
```
$ sudo docker build -t codefordc2/explore-311-data-in-r .
```
Next, launch the server with the following command:
```
$ sudo docker run -d -p 8787:8787 codefordc2/explore-311-data-in-r
```
4. Finally, navigate to localhost:8787 in your favorite browser by pasting "localhost:8787" into the URL bar. If prompted to log in to the RStudio instance, the username and password are both 'rstudio'. You should now see a running version of RStudio with scripts and data related to the 311 data. Now you can run the scripts, view figures, and edit the code in the browser as if you had RStudio running locally on your computer.

## Getting started with our Github project (for contributors)

Start by forking the repository, and then cloning the forked version of the repository to your computer. We use a triangular workflow - you should push to your fork, but fetch/pull from the Code for DC repo. Setting this up is easy. Use these commands:
```
$ git clone <url-of-your-fork>
$ cd the-rat-hack
$ git remote add codefordc https://github.com/eclee25/the-rat-hack.git
$ git remote -v
  #you should see this:
  codefordc       https://github.com/eclee25/the-rat-hack.git (fetch)
  codefordc       https://github.com/eclee25/the-rat-hack.git (push)
  origin          <your/forked/url> (push)
  origin          <your/forked/url> (fetch)
```
Now instead of plain `git push` and `git fetch`, use these:

```
$ git push origin <branch-name>       #pushes to your forked repo
$ git fetch codefordc <branch-name>   #fetches from the codefordc repo
```

Here’s [more information](https://github.com/blog/2042-git-2-5-including-multiple-worktrees-and-triangular-workflows#improved-support-for-triangular-workflows) on setting up triangular workflows (scroll to “Improved support…”).

Never worked with a triangular workflow before? Ask a project lead for help.
