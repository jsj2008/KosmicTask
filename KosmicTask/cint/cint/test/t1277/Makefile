############################################################
# Automatically created makefile for test.dll
############################################################

# Set variables ############################################
CXX         := g++ 
CC          := gcc
LD          := g++ 
CINT        := $(shell which cint)
CINTINCDIRU := $(shell cint-config --unix --incdir)
CINTINCDIRW := $(shell echo  $(CINTINCDIRU) )
CINTLIB     := $(shell cint-config --unix --libdir)/libCint.so
IPATH       := 
CMACRO      :=  -DG__SHAREDLIB -DG__OSFDLL -DG__ANSI -DG__ERRORCALLBACK -DG__SIGNEDCHAR -DG__NEWSTDHEADER -DG__CINT_VER6 -DG__NATIVELONGLONG -DG__P2FCAST -DG__STD_EXCEPTION -DG__MACOSX__ -DG__APPLE -D__DARWIN_UNIX03=1 -DG__HAVE_CONFIG -DG__NOMAKEINFO  -DCINT_HIDE_FAILURE
CXXMACRO    :=   -DG__SHAREDLIB -DG__OSFDLL -DG__ANSI -DG__ERRORCALLBACK -DG__SIGNEDCHAR -DG__NEWSTDHEADER -DG__CINT_VER6 -DG__NATIVELONGLONG -DG__P2FCAST -DG__STD_EXCEPTION -DG__HAVE_CONFIG -DG__NOMAKEINFO  -DCINT_HIDE_FAILURE
CFLAGS      := -O2  -pipe -W -Wall -fsigned-char -fno-common  
CXXFLAGS    := -O2  -pipe -W -Wall -Woverloaded-virtual -fsigned-char -fno-common -D__DARWIN_UNIX03=1 -DG__GNUREADLINE  
CINTIPATH   := -I$(CINTINCDIRW)
OBJECT      := test.dll
LINKSPEC    :=  -DG__CXXLINK_ON

# Set File names ###########################################
CIFC        :=
CIFH        :=
CIFO        :=
CXXIFC      := G__cpp_test.cxx
CXXIFH      := G__cpp_test.h
CXXIFO      := G__cpp_test.o

LIBS        := -L"/Users/Jonathan/Documents/Download/cint-5.18.00/lib" $(subst @imp@,Cint,-l@imp@) -lm -ldl  

CINTOPT     := 
COFILES     := 

CHEADER     := 
CHEADERCINT := 
CSTUB       := 
CSTUBCINT   := 

CXXOFILES   := 

CXXHEADER   :=  ../t1277.h
CXXHEADERCINT :=  ../t1277.h

CXXSTUB     := 
CXXSTUBCINT := 

MAINDIRU    := $(patsubst %/bin/,%/,$(dir $(CINT)))/cint/main/
MAINDIRW    := $(shell echo  $(patsubst %/bin/,%/,$(dir $(shell which cint))))/cint/main/
# Link Object #############################################
$(OBJECT) : $(CINTLIB) $(COFILES) $(CXXOFILES) $(CIFO) $(CXXIFO)
	@$(LD) $(subst @so@,$(OBJECT:.so=), -dynamiclib -single_module) -o $(OBJECT) $(COFILES) $(CIFO) $(CXXIFO) $(CXXOFILES) $(LIBS)

# Compile User source files ##############################

# Compile main function  #################################
G__main.o: $(MAINDIRU)/G__main.c
	@$(CC)  $(CMACRO) $(CFLAGS) $(CCOPT) $(LINKSPEC) $(CINTIPATH) -o $@ -c $<

# Compile dictionary setup routine #######################
G__setup.o: $(MAINDIRU)/G__setup.c $(CINTINCDIRU)/G__ci.h
	@$(CC) $(LINKSPEC) $(CINTIPATH) $(CMACRO) $(CFLAGS) -o $@ -c $(MAINDIRW)/G__setup.c

# Compile C++ Interface routine ##########################
$(CXXIFO) : $(CXXIFC)
	@$(CXX) $(CINTIPATH) $(IPATH) $(CXXMACRO) $(CXXFLAGS) $(CCOPT) -c $(CXXIFC)

# Create C++ Interface routine ###########################
$(CXXIFC) : $(CXXHEADER) $(CXXSTUB) $(CINT)
	@$(CINT)  -w2 -ztest -n$(CXXIFC) $(DLLSPEC) -D__MAKECINT__ -DG__MAKECINT  -c-1 -A $(CINTIPATH) $(IPATH) $(CXXMACRO) $(CINTOPT) $(CXXHEADERCINT)

# Clean up #################################################

clean :
	@$(RM) $(OBJECT) core $(CIFO) $(CIFC) $(CIFH) $(CXXIFO) $(CXXIFC) $(CXXIFH) $(RMCOFILES) $(RMCXXOFILES)

# re-makecint ##############################################
makecint :
	makecint  -mk Makefile -q -DCINT_HIDE_FAILURE -dl test.dll -H ../t1277.h

