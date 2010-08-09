################################################################
# Makefile for tkz-orm                                         #
################################################################

help:
	@echo ""
	@echo " make clean    - clean out directory"
	@echo " make tidy     - clean out directory some more"
	@echo " make examples - create examples as PDF and PNG"
	@echo " make ctan     - create a CTAN-ready archive"
	@echo " make doc      - typeset documentation"
	@echo " make install  - install files in local texmf tree"
	@echo ""

################################################################
# Master package name                                          #
################################################################

PACKAGE = tkz-orm
FEATURES = index bib

LATEXFLAGS = -interaction=nonstopmode

################################################################
# Directory structure for making zip files                     #
################################################################

CTANROOT := ctan
CTANDIR  := $(CTANROOT)/$(PACKAGE)
CTANINCLUDE = $(PACKAGE).tex $(PACKAGE).sty $(PACKAGE).bib \
	README LICENSE pgfmanualstyle.sty Makefile

###############################################################
# Data for local installation
###############################################################

# TODO: add cheatsheet
INCLUDEPDF  := $(PACKAGE)
PACKAGEROOT := latex/$(PACKAGE)

################################################################
# Clean-up information                                         #
################################################################

AUXFILES = aux bbl bit blg glo gls dvi glo hd idx ilg ind lof \
	log nlo nls out toc

CLEAN = gz pdf ps zip

################################################################
# File buiding: default actions                                #
################################################################

all: $(PACKAGE).pdf
index: $(PACKAGE).ind $(PACKAGE).ilg
abbr: $(PACKAGE).nls
bib: $(PACKAGE).blg $(PACKAGE).bbl

# Documentation
$(PACKAGE).pdf: $(PACKAGE).tex $(FEATURES)
	pdflatex $(LATEXFLAGS) $(PACKAGE).tex
	pdflatex $(LATEXFLAGS) $(PACKAGE).tex
 
# Preperation
$(PACKAGE).idx $(PACKAGE).nlo $(PACKAGE).aux: $(PACKAGE).tex
	pdflatex $(LATEXFLAGS) $(PACKAGE).tex
 
# Indexes
$(PACKAGE).ind $(PACKAGE).ilg: $(PACKAGE).tex $(PACKAGE).idx
	makeindex $(PACKAGE).idx

$(PACKAGE).nls: $(PACKAGE).tex $(PACKAGE).nlo
	makeindex $(PACKAGE).nlo -s nomencl.ist -o $(PACKAGE).nls

# Bibliography
$(PACKAGE).blg $(PACKAGE).bbl: $(PACKAGE).tex $(PACKAGE).bib $(PACKAGE).aux
	bibtex $(PACKAGE)

%.pdf2: %.tex
	NAME=`basename $< .tex` ; \
	echo "Typesetting $$NAME" ; \
	pdflatex &> /dev/null ; \
	if [ $$? = 0 ] ; then  \
	  makeindex -s gglo.ist -o $$NAME.gls $$NAME.glo &> /dev/null ; \
	  makeindex -s gind.ist -o $$NAME.ind $$NAME.idx &> /dev/null ; \
	  pdflatex &> /dev/null ; \
	  pdflatex &> /dev/null ; \
	else \
	  echo "  Complilation failed" ; \
	fi ; \
	for I in $(AUXFILES) ; do \
	  rm -f $$NAME.$$I ; \
	done

%.png: %.tex
	@sed 's/^\\begin{document}/\
\\pgfrealjobname{dummy}\\begin{document}\\beginpgfgraphicnamed{example}/' $< | \
sed 's/^\\end{document}/\\endpgfgraphicnamed\\end{document}/' > example.tex ; \
	pdflatex --jobname=example example.tex ; \
	gs -dNOPAUSE -r120 -dGraphicsAlphaBits=4 -dTextAlphaBits=4 -sDEVICE=png16m \
-sOutputFile=$@ -dBATCH example.pdf ; \
	convert -thumbnail 200 $@ $(addsuffix .thumb.png, $(basename $@)) ; \
	mv example.pdf $(addsuffix .pdf, $(basename $<)) ; rm example.*


################################################################
# User make options                                            #
################################################################

.PHONY = clean tidy install

clean:
	for I in $(AUXFILES) $(CLEAN) ; do \
	  rm -f *.$$I ; \
	done
	@rm -rf $(CTANROOT)/

tidy: clean
	@rm -rf *~

ctan: doc
	echo "Creating CTAN archive"
	mkdir -p $(CTANDIR)/
	rm -rf $(CTANDIR)/*
	for I in $(INCLUDEPDF) ; do \
	  cp -f $$I.pdf $(CTANDIR)/ ; \
	done ; \
	for F in $(CTANINCLUDE) ; do \
	  cp -f $$F $(CTANDIR)/ ; \
	done ; \
	cd $(CTANDIR) ; \
	zip -ll -q -r -X $(PACKAGE).zip .
	cp $(CTANDIR)/$(PACKAGE).zip ./
	rm -rf $(CTANROOT)/

doc: $(foreach FILE,$(INCLUDEPDF),$(FILE).pdf)

examples: $(foreach FILE,$(wildcard examples/*.tex),$(basename $(FILE)).png)

install: 
	echo Installing $(PACKAGE).sty
	TEXMFHOME=`kpsewhich --var-value=TEXMFHOME` ; \
	rm -rf $$TEXMFHOME/tex/$(PACKAGEROOT)/*.* ; \
	mkdir -p $$TEXMFHOME/tex/$(PACKAGEROOT)/ ; \
	cp $(PACKAGE).sty $$TEXMFHOME/tex/$(PACKAGEROOT)/ ; \
	texhash &> /dev/null
