
#frwk-sh, the Shell Script Framework

To give you a short yet complete overview on the Shell Script Framework,
the following topics are covered in this README:

1. WTF
2. What it is NOT
3. Best practices
4. Portability
5. Usability
6. Getting started
7. Bugs

##What's This Framework (for) ?
 This framework is meant to automatize the process of creating proper command 
 line interfaces for shell scripts by providing a template for argument handling,
 runtime information output and usage documentation.
 As a framework, frwk-sh embraces (and never touches) the task-specific code that YOU
 wrote with the cli-functionality a proper script should have. Since cli-functionality
 includes proper documentation, the task of providing usage documentation has been
 simplified as much as possible and integrating that documentation into your script has
 been automatized to the point of a simple 'make' run.

##What it is NOT
 The framework is NOT meant to be a scripting library that provides you with extra functionality
 that you may or may not need (even though libraries are part of the framework).
 The framework is rather meant as a wrapper around your existing code to serve as both
 motivation and standardization effort when starting a script from scratch.

##Best Practices
 In order to increase a script's robustness, the "unofficial strict mode" is turned
 on, an exit handler is installed and e.g. the builtin echo command is replaced with
 a more portable function using printf. The idea is to implement default
 code that helps to avoid / miss otherwise undetected errors and to implement
 best practices, especially with regards to portability of script code,
 wherever this is feasible without the programmer's intervention.
 The easily customizable exit handler takes care of gracefully exiting your script
 if it gets interrupted and allows you to easily cleanup after yourself.
 You will find various references in both the code and the documentation to
 internet resources on shell script programming. The Script Framework is meant
 to be an implementation of the ideas presented in those resources.

##Portability
 All Shell Script Framework code is written with portability in mind, since relying
 on a certain shell's specific behaviour may work on many systems and fail with
 spurious errors on others. 
 Due to the widespread use of bash as the standard shell, portability is  
 considered to be roughly equivalent with "avoid bashisms".
 All frwk-sh code will run perfectly well when executed by bash, yet will continue
 to do so when executed by (hopefully) any other POSIX-compliant shell,
 e.g. on Debian-derivates where a call to /bin/sh executes "dash" as the default
 non-interactive shell.
 If you can't see why avoiding bashism is a good idea, you don't care about the 
 speed of execution benefits a shell like dash comes with and you don't care about
 the portability of your script code, you can still produce as many bashisms as you want
 in YOUR portion of the code. After all, it's meant to be a framework, not an ideology.
 
##Usability
 An improved getopts version is provided via the cli library. This library is included
 into the resulting script by default. It is self-contained in the sense that it  is
 entirely written in shell code, supports --long-options (as well as the short
 ones, of course) and forms the backbone of command line handling support in the
 framework. Furthermore, the framework provides a default usage text (taken from
 the util-linux project) that just needs to be edited to match the scripts command line
 options. 
 Runtime output functions are available to easily provide the user with a response
 in a format known from most of the coreutils / util-linux applications.  
 Most scripts will not require a full man page, yet creation of a man page
 is supported as well. All it takes is editing the provided default man page,
 and running 'make man'. Or simply run 'make man' to get a demo man page.

##Getting started
 If you want to give the Script Framework a try, download the sources and
 run 'make' to create the frwk-sh tool which is the command line interface to the
 Shell Script Framework.
 Running e.g. 'frwk-sh foo' will create a directory named <foo> which contains your
 first Shell Script Framework project.
 Change into <foo> and run 'make', which will create a default script named "foo",
 which does not do anything apart from serving as an example for the functionality a
 Shell Script Framwork provides by default. All it takes is to edit "foo.sh" in 
 that directory and re-run 'make' until your happy with the result.
 Change into <foo> and run 'make man', which will create a demo man page "foo.1.gz",
 read that man page for instructions on how to create your own man page.
 Run 'make help' for a list of targets provided by the Makefile.

##Bugs
 Shared libraries are not functional yet, so far it's static libraries only 
 that are implemented into the script.

									fgndevelop
