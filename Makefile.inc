CLEANDIRS = $(addsuffix .clean, $(DIRS))
DIRSALL = $(addsuffix /all.rel, $(DIRS))
DEPS = $(addsuffix .dep, $(basename $(RELS)))

MAKEDEP = makedep.pl
AS = as6809 -oxs

%.rel: %.asm %.d
	$(MAKEDEP) $< $@ > $(addsuffix .dep, $(basename $<))
	$(AS) $@ $<

%.d: ;
.PRECIOUS: %.d

.PHONY: $(DIRS) $(CLEANDIRS)

all.rel: $(DIRSALL) $(RELS)
	cat $(DIRSALL) $(RELS) > all.rel

$(DIRSALL): $(DIRS)
	$(MAKE) -C $(dir $@)

$(CLEANDIRS):
	$(MAKE) -C $(basename $@) clean

clean: $(CLEANDIRS)
	rm -f $(RELS) $(DEPS) all.rel *.sym

-include $(DEPS)
