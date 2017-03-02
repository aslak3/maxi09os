CLEANDIRS = $(addsuffix .clean, $(DIRS))

%.rel: %.asm
	as6809 -oxs $@ $<

.PHONY: $(DIRS) $(CLEANDIRS)

all.rel: $(RELS) $(DIRS)
	cat $(addsuffix /all.rel, $(DIRS)) $(RELS) > all.rel

$(DIRS):
	$(MAKE) -C $@

$(CLEANDIRS):
	$(MAKE) -C $(basename $@) clean

clean: $(CLEANDIRS)
	rm -f $(RELS) all.rel *.sym *.joined
