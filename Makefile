all: package

package: amaroklcd.pl
	mkdir amaroklcd
	cp amaroklcd.pl README amaroklcd.spec Object.pm Controller.pm InfoControl.pm LCDManager.pm SliderControl.pm amaroklcd
	tar jcvf amaroklcd-`getver.sh amaroklcd.pl`.amarokscript.tar.bz2 amaroklcd
	rm -rf amaroklcd
	mv amaroklcd-`getver.sh amaroklcd.pl`.amarokscript.tar.bz2 ../tags/releasefiles/

clean: 
	rm -rf *.bz2

