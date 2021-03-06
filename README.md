Welcome!
========

This project aims to create a website that serves as a starting point for people
who are new to the PHP community. We want to provide a collection of useful
resources that help them to become a part of the community.

Contributing
============
Thanks for considering a contribution to our project! Creating a development
environment for this project is relatively easy because we use
[Vagrant](http://www.vagrantup.com). This tool allows you to set up and tear
down your development environment inside of a
[VirtualBox](http://virtualbox.org) VM. Since this VM emulates the configuration
of our actual production server as closely as possible, code that works on your
development VM should work in production as well. That's the theory, at least.

Installation
------------
1.  Install the latest versions of VirtualBox, the VirtualBox Extension Pack
    and Vagrant for your operating system

2.  Add the following lines to your /etc/hosts or
    C:\Windows\System32\drivers\etc\hosts file:

        192.168.33.10 welcome-to-php.dev www.welcome-to-php.dev
        192.168.33.10 xhprof.welcome-to-php.dev phpmyadmin.welcome-to-php.dev

3.  Clone our repository

4.  Run this command in the directory you cloned:

        vagrant up
