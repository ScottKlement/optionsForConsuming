.SECONDARY:
.PRECIOUS:

.SECONDEXPANSION:
.ONESHELL:
SHELL = /usr/bin/qsh
.SHELLFLAGS = -ec

VERSION        := 0.1
COPYRIGHT      := Version $(VERSION). Copyright 2001-2023 Scott C. Klement.
LIBRARY				 ?= SKWEBSRV
YAJLLIB				 ?= YAJL
HTTPLIB				 ?= LIBHTTP
TGTRLS         ?= *current
DEBUG					 ?= 1

ifneq (,$(BUILDLIB))
LIBRARY=$(BUILDLIB)
endif

# Make sure LIBRARY has been set and doesn't have any blanks
ifneq (1,$(words [$(LIBRARY)]))
$(error LIBRARY variable is not set correctly. Set to a valid library name and try again)
endif
ifeq (,$(LIBRARY))
$(error LIBRARY variable is not set correctly. Set to a valid library name and try again)
endif

ILIBRARY      := /qsys.lib/$(LIBRARY).lib
IPKGLIB       := /qsys.lib/$(PKGLIB).lib
RPGINCDIR     := 'src/rpgleinc'
RPGINCDIR     := incdir($(RPGINCDIR))
CINCDIR       := 'include'
CINCDIR       := incdir($(CINCDIR))
BNDDIR        :=
C_OPTS				:= localetype(*localeucs2) sysifcopt(*ifsio)
CL_OPTS       :=
RPG_OPTS      := option(*noseclvl)
PGM_OPTS      :=
OWNER         := qpgmr
DEBUG         := 0
USRPRF        := *user
BNDSRVPGM			:=
PGM_ACTGRP		:= OPTIONS
SRVPGM_ACTGRP := *caller

SETLIBLIST    := liblist | grep ' USR' | while read lib type; do liblist -d $$lib; done; liblist -a $(LIBRARY); liblist -a $(YAJLLIB); liblist -a $(HTTPLIB)
TMPSRC        := tmpsrc
ISRCFILE      := $(ILIBRARY)/$(TMPSRC).file
SRCFILE       := srcfile($(LIBRARY)/$(TMPSRC)) srcmbr($(TMPSRC))
SRCFILE2      := $(LIBRARY)/$(TMPSRC)($(TMPSRC))
SRCFILE3      := file($(LIBRARY)/$(TMPSRC)) mbr($(TMPSRC))
PRDLIB        := $(LIBRARY)
TGTCCSID      := *job
DEVELOPER     ?= $(USER)
MAKE          := make
LOGFILE       = $(CURDIR)/tmp/$(@F).txt
OUTPUT        = >$(LOGFILE) 2>&1

# Remove compile listings from previous `make`
$(shell test -d $(CURDIR)/tmp || mkdir $(CURDIR)/tmp; rm $(CURDIR)/tmp/*.txt >/dev/null 2>&1)

#
# Set variables for adding in a debugging view if desired
#

ifeq ($(DEBUG), 1)
	DEBUG_OPTS     := dbgview(*all)
	SQL_DEBUG_OPTS := dbgview(*source)
	CPP_OPTS       := $(CPP_OPTS) output(*print)
else
	DEBUG_OPTS     := dbgview(*none)
	SQL_DEBUG_OPTS := dbgview(*none)
	CPP_OPTS       := $(CPP_OPTS) optimize(40) output(*none)
	RPG_OPTS       := $(RPG_OPTS) optimize(*full)
endif

define TARGET_DSPF
  WATSONTR1D.file WATSONTR2D.file WATSONTR3D.file 
endef	
TARGET_DSPF := $(addprefix $(ILIBRARY)/, $(TARGET_DSPF))

define TARGET_PGMS
	WATSONTR1R.pgm WATSONTR2R.pgm WATSONTR3R.pgm WATSONTR4R.pgm WATSONTR5R.pgm
	WATSONTR6R.pgm WATSONTR7R.pgm
endef	
TARGET_PGMS := $(addprefix $(ILIBRARY)/, $(TARGET_PGMS))

TARGETS := $(TARGET_DSPF) $(TARGET_PGMS)

WATSONTR1R.module_deps := src/rpgleinc/VERSION.rpgleinc
WATSONTR2R.module_deps := src/rpgleinc/VERSION.rpgleinc
WATSONTR3R.module_deps := src/rpgleinc/VERSION.rpgleinc
WATSONTR4R.module_deps := src/rpgleinc/VERSION.rpgleinc
WATSONTR5R.module_deps := src/rpgleinc/VERSION.rpgleinc
WATSONTR6R.module_deps := src/rpgleinc/VERSION.rpgleinc
WATSONTR7R.module_deps := src/rpgleinc/VERSION.rpgleinc

WATSONTR1R.pgm_deps := $(addprefix $(ILIBRARY)/, WATSONTR1R.module WATSONTR1D.file)
WATSONTR2R.pgm_deps := $(addprefix $(ILIBRARY)/, WATSONTR2R.module WATSONTR2D.file)
WATSONTR3R.pgm_deps := $(addprefix $(ILIBRARY)/, WATSONTR3R.module WATSONTR3D.file)
WATSONTR4R.pgm_deps := $(addprefix $(ILIBRARY)/, WATSONTR4R.module WATSONTR3D.file)
WATSONTR5R.pgm_deps := $(addprefix $(ILIBRARY)/, WATSONTR5R.module WATSONTR3D.file)
WATSONTR6R.pgm_deps := $(addprefix $(ILIBRARY)/, WATSONTR6R.module WATSONTR3D.file)
WATSONTR7R.pgm_deps := $(addprefix $(ILIBRARY)/, WATSONTR7R.module WATSONTR3D.file)

.PHONY: all clean

all: $(TARGETS) | $(ILIBRARY) 

clean:
	rm -rf $(ISRCFILE) $(EXAMPLES) $(TARGET_PGMS) $(TARGET_DSPF) $(ILIBRARY)/*.MODULE
	rm -f src/rpgleinc/VERSION.rpgleinc
	rm -rf src/rpgleinc tmp

$(ILIBRARY): | tmp
	-system -v 'crtlib lib($(LIBRARY)) type(*PROD)'
	system -v "chgobjown obj($(LIBRARY)) objtype(*lib) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)) objtype(*lib) user(*public) aut(*use) replace(*yes)"

$(IPKGLIB):
	-system -v 'crtlib lib($(PKGLIB)) type(*PROD)'
	system -v "chgobjown obj($(PKGLIB)) objtype(*lib) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(PKGLIB)) objtype(*lib) user(*public) aut(*use) replace(*yes)"

$(ISRCFILE): | $(ILIBRARY)
	-system -v 'crtsrcpf rcdlen(250) $(SRCFILE3)'

src/rpgleinc:
	mkdir $(CURDIR)/src/rpgleinc

tmp:
	mkdir $(CURDIR)/tmp	

#
#  Specific rules for objects that don't follow the "cookbook" rules, below.
#

src/rpgleinc/VERSION.rpgleinc: src/rpgleinc
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -f '$(@)'
	touch -C 819 '$(@)'
	echo "     H COPYRIGHT('$(COPYRIGHT) +" >> '$(@)'
	echo "     H All rights reserved. A file called LICENSE was included +" >> '$(@)'
	echo "     H with this distribution and contains important license +" >> '$(@)'
	echo "     H information.')" >> '$(@)') $(OUTPUT)

src/rpgleinc/HTTPAPI_H.rpgleinc: src/rpgleinc
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -f '$(@)'
	ln -s /qsys.lib/$(HTTPLIB).lib/QRPGLESRC.file/HTTPAPI_H.mbr src/rpgleinc/HTTPAPI_H.rpgleinc) $(OUTPUT)

src/rpgleinc/YAJL_H.rpgleinc: src/rpgleinc
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -f '$(@)'
	ln -s /qsys.lib/$(YAJLLIB).lib/QRPGLESRC.file/HTTPAPI_H.mbr src/rpgleinc/YAJL_H.rpgleinc) $(OUTPUT)

#
#  Standard "cookbook" recipes for building objects
#
$(ILIBRARY)/%.module: src/clsrc/%.clle | $(ISRCFILE) $$($$*.module_files) $$($$*.module_spgms)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	system -v "crtclmod module($(LIBRARY)/$(*F)) $(SRCFILE) $(CL_OPTS) tgtrls($(TGTRLS)) $(DEBUG_OPTS)") $(OUTPUT)
							
$(ILIBRARY)/%.module: src/csrc/%.c $$($$*.module_deps) | $(ILIBRARY)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	system -v "crtcmod module($(LIBRARY)/$(*F)) srcstmf('$(<)') $(CINCDIR) $(C_OPTS) tgtrls($(TGTRLS)) $(DEBUG_OPTS) tgtccsid($(TGTCCSID))") $(OUTPUT)
	
$(ILIBRARY)/%.module: src/rpglesrc/%.rpgle $$($$*.module_deps) | $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	system -v "crtrpgmod module($(LIBRARY)/$(*F)) $(SRCFILE) $(RPGINCDIR) $(RPG_OPTS) tgtrls($(TGTRLS)) $(DEBUG_OPTS)") $(OUTPUT)
	
$(ILIBRARY)/%.module: src/rpglesrc/%.sqlrpgle $$($$*.module_deps) | $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	system -v "crtsqlrpgi obj($(LIBRARY)/$(*F)) $(SRCFILE) compileopt('$(subst ','',$(RPGINCDIR)) $(subst ','',$(RPG_OPTS))') $(SQL_OPTS) tgtrls($(TGTRLS)) $(SQL_DEBUG_OPTS) objtype(*module) rpgppopt(*lvl2)") $(OUTPUT)
	
$(ILIBRARY)/%.pnlgrp: src/pnlsrc/%.pnlgrp | $$($$*.pnlgrp_deps) $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	system -v "crtpnlgrp pnlgrp($(LIBRARY)/$(*F)) $(SRCFILE)"
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)

$(ILIBRARY)/%.cmd: src/cmdsrc/%.cmd $$($$*.cmd_deps) | $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	system -v 'crtcmd cmd($(LIBRARY)/$(*F)) $(SRCFILE) pgm(*libl/$(*F)) prdlib($(PRDLIB))'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)

$(ILIBRARY)/%.pgm: $$($$*.pgm_deps) $(ILIBRARY)/%.module | $(ILIBRARY) $$($$*.pgm_files) $$($$*.pgm_spgms)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	system -v 'dltpgm pgm($(LIBRARY)/$(*F))' || true
	system -v 'crtpgm pgm($(LIBRARY)/$(*F)) module($(foreach MODULE, $(notdir $(filter %.module, $(^))), ($(LIBRARY)/$(basename $(MODULE))))) entmod(*pgm) $(PGM_OPTS) actgrp($(PGM_ACTGRP)) tgtrls($(TGTRLS)) bndsrvpgm($(foreach SRVPGM, $(notdir $(filter %.srvpgm, $(|))), ($(basename $(SRVPGM))))) $(BNDDIR) $($(@F)_opts) usrprf($(USRPRF))'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)
			
$(ILIBRARY)/%.srvpgm: src/srvsrc/%.bnd $$($$*.srvpgm_deps) | $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -rf '$(@)'
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	$(SETLIBLIST)
	system -v 'dltsrvpgm srvpgm($(LIBRARY)/$(*F))' || true
	system -v 'crtsrvpgm srvpgm($(LIBRARY)/$(*F)) module($(foreach MODULE, $(notdir $(filter %.module, $(^))), ($(LIBRARY)/$(basename $(MODULE))))) $(SRCFILE) $(PGM_OPTS) actgrp($(SRVPGM_ACTGRP)) tgtrls($(TGTRLS)) bndsrvpgm($(foreach SRVPGM, $(notdir $(filter %.srvpgm, $(^))), ($(basename $(SRVPGM))))) $($(@F)_opts) $(BNDDIR) usrprf($(USRPRF))'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)

$(ILIBRARY)/%.file: src/ddssrc/%.dspf | $$($$*.file_deps) $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -rf '$(@)'
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	$(SETLIBLIST)
	system -v 'crtdspf file($(LIBRARY)/$(*F)) $(SRCFILE)'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)

build:
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -rf build
	mkdir build) $(OUTPUT)
