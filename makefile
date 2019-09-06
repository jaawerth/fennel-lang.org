.DEFAULT_GOAL := build

TAGS := $(shell git --git-dir=./fennel/.git tag -l | grep '^[0-9]' | tac)
TAGDIRS := master $(foreach tag, $(TAGS), v${tag})

# which fennel/$.md files build a tag index
TAGSOURCES := changelog reference api

HTML := tutorial.html api.html reference.html lua-primer.html changelog.html
LUA := generate.lua fennelview.lua

# This requires pandoc 2.0+
PANDOC=pandoc --syntax-definition fennel-syntax.xml \
	-H head.html -A foot.html -T "Fennel"

index.html: main.fnl sample.html ; fennel/fennel main.fnl $(TAGDIRS) > index.html
fennelview.lua: fennel/fennelview.fnl ; fennel/fennel --compile $^ > $@
generate.lua: fennel/generate.fnl ; fennel/fennel --compile $^ > $@

%.html: fennel/%.md ; $(PANDOC) -o $@ $^

# TODO: for now all master and tags are generated the same;
# there might be time, when we have "generations" of fennel
# TODO: dedupe v% and master setup here
v%/fennel: ; git clone --branch $* fennel $@
v%/index.html: $(foreach md, $(TAGSOURCES), v%/fennel/${md}.md); $(PANDOC) -o $@ $^
master/fennel: ; git clone --branch master fennel $@
master/index.html: $(foreach md, $(TAGSOURCES), master/fennel/${md}.md); $(PANDOC) -o $@ $^

tagdirs: ; $(foreach tagdir, $(TAGDIRSS), mkdir -p ${tagdir})
cleantagdirs: ; $(foreach tagdir, $(TAGDIRS), rm -rf ${tagdir})
tags: tagdirs $(foreach tagdir, $(TAGDIRS), ${tagdir}/fennel)
TAGDOCS := $(foreach tagdir, $(TAGDIRS), $(addprefix ${tagdir}/, index.html))

build: html lua tagdocs
html: $(HTML) index.html
tagdocs: tags $(TAGDOCS)
lua: $(LUA)
clean: cleantagdirs ; rm -f $(HTML) index.html $(LUA)

upload: $(HTML) $(LUA) $(TAGDIRS) index.html init.lua repl.fnl fennel.css \
		fengari-web.js .htaccess fennel
	rsync -r $^ fenneler@fennel-lang.org:fennel-lang.org/

conf/%.html: conf/%.fnl ; fennel/fennel $^ > $@

conf/thanks.html: conf/thanks.fnl ; fennel/fennel $^ > $@
conf/signup.cgi: conf/signup.fnl
	echo "#!/usr/bin/env lua" > $@
	fennel/fennel --compile $^ >> $@
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
