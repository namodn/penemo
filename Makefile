PREFIX=/usr/local/test
EXE_PERMS=755

DOC=share/penemo/doc
PERMS_DOC=777

LIB=share/penemo/lib
PERMS_LIB=777

HTML=share/penemo/html
PERMS_TMPL=777

BIN=bin
PERMS_BIN=777


INCLUDE=${EXEC}
CGIPATH=/cgi

#PERLEXT=
# for compatibility reasons: use _PERL internally, accept PERL as a make 
# argument
#PERL=`./perlpath`
#_PERL=$(shell if [ "${PERL}" = "" ]; then ./perlpath; else echo ${PERL}; fi)

all:
	@echo "use 'make install' to install"

install: inst-doc inst-lib inst-tmpl inst-bin
	

inst-doc:
	echo "Installing documentation..."
	./mkdirto.pl $(PERMS_DOC) $(PREFIX)/$(DOC)
	cp -rp doc/* $(PREFIX)/$(DOC)/

inst-lib:
	echo "Installing libraries..."
	./updatelibdir.pl $(PREFIX)/$(LIB) lib/
	./mkdirto.pl $(PERMS_LIB) $(PREFIX)/$(LIB)
	cp -rp lib/* $(PREFIX)/$(LIB)/

inst-tmpl:
	echo "Installing html files..."
	./mkdirto.pl $(PERMS_TMPL) $(PREFIX)/$(HTML)
	cp -rp html/* $(PREFIX)/$(HTML)/

inst-bin:
	echo "Installing penemo binary..."
	./updatelibdir.pl $(PREFIX)/$(LIB) bin/
	./mkdirto.pl $(PERMS_BIN) $(PREFIX)/$(BIN)
	cp -rp bin/penemo $(PREFIX)/$(BIN)
	#chown root:root $(PREFIX)/$(BIN)/penemo
	chmod $(EXE_PERMS) $(PREFIX)/$(BIN)/penemo

