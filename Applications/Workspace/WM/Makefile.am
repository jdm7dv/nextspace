## Process this file with automake to produce Makefile.in

AUTOMAKE_OPTIONS =

BUILT_SOURCES = config-paths.h

DISTCLEANFILES = config-paths.h

config.h: config-paths.h

config-paths.h: Makefile
	@echo "Generating $@"
	@echo '/* this is a generated file - do not edit */' > $@
	@echo '' >> $@
	@echo '/* define where the translations are stored */' >> $@
	@echo '#define LOCALEDIR "$(localedir)"' >> $@
	@echo '' >> $@
	@echo '/* define an extra path for pixmaps */' >> $@
	@echo '#define PIXMAPDIR "$(pixmapdir)"' >> $@
	@echo '' >> $@
	@echo '/* where shared data is stored */' >> $@
	@echo '#define PKGDATADIR "$(datadir)/WindowMaker"' >> $@
	@echo '' >> $@
	@echo '/* where the configuration is stored */' >> $@
	@echo '#define SYSCONFDIR "$(sysconfdir)"' >> $@

ACLOCAL_AMFLAGS = -I m4

# Improve coverage in 'make distcheck' by checking that translations work
AM_DISTCHECK_CONFIGURE_FLAGS = --enable-silent-rules LINGUAS='*'


SUBDIRS = WINGs src po
DIST_SUBDIRS = $(SUBDIRS)


.PHONY:	coverage-reset coverage

if USE_LCOV
coverage-reset:
	find . -type f -name '*.gcda' -exec rm -f '{}' ';'
	lcov --directory . --zerocounters

coverage:
	rm -rf coverage @lcov_output_directory@
	-mkdir -p coverage @lcov_output_directory@
	lcov --compat-libtool --capture --directory . --output-file coverage/coverage.info
	genhtml --output-directory @lcov_output_directory@ coverage/coverage.info
endif

# make update-lang PO=<lang>
# ==========================
# Update the PO files against the POT file in all the translation sub-directories
#
# We do not use an automatic recursive target from Automake (AM_EXTRA_RECURSIVE_TARGETS)
# because we want to check only once that the variable PO was defined; the added bonus
# being that we do not process all directories but only the related ones, which is
# faster and a lot less verbose

update-lang:
if HAVE_XGETTEXT
	@if echo "$(PO)" | grep -v '^[a-z][a-z]\(_[A-Z][A-Z]\)\?$$' > /dev/null ; then \
	  echo "Error: invalid value \"$(PO)\" for update-lang, use PO=<lang>" >&2 ; exit 1 ; \
	fi ; \
	for subdir in $(SUBDIRS_PO); do \
	  ($(am__cd) $$subdir && $(MAKE) $(AM_MAKEFLAGS) update-lang || exit $$?); \
	done

SUBDIRS_PO = WINGs/po po
else
	@echo "Error: the program 'xgettext' was not found by configure, it is mandatory for this operation" >&2 ; exit 1
endif

.PHONY: update-lang

# Create a 'silent-rule' for our make check the same way automake does
AM_V_CHKOPTS = $(am__v_CHKOPTS_$(V))
am__v_CHKOPTS_  = $(am__v_CHKOPTS_$(AM_DEFAULT_VERBOSITY))
am__v_CHKOPTS_0 = @echo "  CHK      $@" ;
am__v_CHKOPTS_1 =
