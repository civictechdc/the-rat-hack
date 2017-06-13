# Code for DC - The Rat Hack

This is the Code for DC rats project. We are exploring data on rodent abatement complaints submitted to DC 311. The short-term goal is to visualize historical data on 311 calls and search for simple correlations with potential mechanisms for rat complaints. The long-term goal is to develop a model that can predict clusters of 311 rodent complaints in time and space, as an informative tool for city managers.

## Getting Started with our Github Project

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
