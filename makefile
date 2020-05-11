.DEFAULT_GOAL := build

TAGS := $(shell git --git-dir=./fennel/.git tag -l | grep '^[0-9]' | grep -v - | tac)
TAGDIRS := master $(foreach tag, $(TAGS), v${tag})

# which fennel/$.md files build a tag index
TAGSOURCES := changelog reference api setup

HTML := tutorial.html api.html reference.html lua-primer.html changelog.html
LUA := generate.lua fennelview.lua

# This requires pandoc 2.0+
PANDOC=pandoc --syntax-definition fennel-syntax.xml \
	-H head.html -A foot.html -T "Fennel" \
	--lua-filter=promote-h1-to-title.lua

fennel/fennel: ; make -C fennel fennel

index.html: main.fnl sample.html fennel/fennel
	fennel/fennel main.fnl $(TAGDIRS) > index.html
%.lua: fennel/%.fnl fennel/fennel ; fennel/fennel --compile $< > $@

reference.html: fennel/reference.md ; $(PANDOC) --toc -o $@ $^
%.html: fennel/%.md ; $(PANDOC) -o $@ $^

# TODO: for now all master and tags are generated the same;
# there might be time, when we have "generations" of fennel

%/tag-intro.md: fennel/fennel ; fennel/fennel tag-intro.fnl $@ > $@
%/repl.md: repl.md ; cp $^ $@
%/init.lua: init.lua ; cp $^ $@
%/repl.fnl: repl.fnl ; cp $^ $@
%/fennelview.lua: %/fennel/fennelview.fnl %/fennel/fennel
	$*/fennel/fennel --compile $< > $@
%/generate.lua: %/fennel/generate.fnl %/fennel/fennel
	$*/fennel/fennel --compile $< > $@

v%/fennel:
	git clone --branch $* fennel $@
	make -C $(@D) fennel
	touch setup.md # not all tags have this

master/fennel:
	git clone --branch master fennel $@
	make -C $(@D) fennel

v%/index.html: v%/tag-intro.md v%/repl.md $(foreach md, $(TAGSOURCES), \
		v%/fennel/${md}.md)
	$(PANDOC) -o $@ $^

master/index.html: master/tag-intro.md master/repl.md \
		$(foreach md, $(TAGSOURCES), master/fennel/${md}.md)
	$(PANDOC) -o $@ $^ && rm master/tag-intro.md

tagdirs: ; $(foreach tagdir, $(TAGDIRSS), mkdir -p ${tagdir})
cleantagdirs: ; $(foreach tagdir, $(TAGDIRS), rm -rf ${tagdir})
tags: tagdirs $(foreach tagdir, $(TAGDIRS), ${tagdir}/fennel)
TAGDOCS := $(foreach tagdir, $(TAGDIRS), \
	$(foreach file, index.html init.lua repl.fnl fennelview.lua generate.lua, \
		${tagdir}/${file}))

build: html lua tagdocs
html: $(HTML) index.html
tagdocs: tags $(TAGDOCS)
lua: $(LUA)
clean: cleantagdirs ; rm -f $(HTML) index.html $(LUA)

upload: $(HTML) $(LUA) $(TAGDIRS) index.html init.lua repl.fnl fennel.css \
		fengari-web.js .htaccess fennel
	rsync -r $^ fenneler@fennel-lang.org:fennel-lang.org/

conf/%.html: conf/%.fnl fennel/fennel ; fennel/fennel $< > $@

conf/thanks.html: conf/thanks.fnl fennel/fennel ; fennel/fennel $< > $@
conf/signup.cgi: conf/signup.fnl fennel/fennel
	echo "#!/usr/bin/env lua" > $@
	fennel/fennel --compile $< >> $@
	chmod 755 $@

uploadconf: conf/*.html conf/*.jpg conf/.htaccess fennelview.lua conf/signup.cgi
	rsync $^ fenneler@fennel-lang.org:conf.fennel-lang.org/

uploadv: conf/v
	rsync -r $^ fenneler@fennel-lang.org:conf.fennel-lang.org/

pullsignups:
	ls signups/ | wc -l
	rsync -rv fenneler@fennel-lang.org:conf.fennel-lang.org/signups/*fnl signups/
	ls signups/ | wc -l
	fennel signups.fnl

.PHONY: build html tagdirs tagdocs lua clean cleantagdirs upload uploadv uploadconf pullsignups
