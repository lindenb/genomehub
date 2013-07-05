include config.mk
GENDIR=src/main/generated-sources/java
.PHONY:all clean generatecode

all: generatecode

bin/faToTwoBit : 
	mkdir -p $(dir $@)
	curl -o $@ "http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/$(notdir $@)"

generatecode: $(GENDIR)/com/github/lindenb/genomehub/ObjectFactory.java \
			$(GENDIR)/org/uniprot/uniprot/ObjectFactory.java \
			$(GENDIR)/gov/nih/nlm/ncbi/blast/ObjectFactory.java

$(GENDIR)/com/github/lindenb/genomehub/ObjectFactory.java : src/main/resources/xsd/genomehub.xsd
	mkdir -p $(GENDIR)
	xjc ${XJCPROXY} -d $(GENDIR) -p com.github.lindenb.genomehub $<

$(GENDIR)/org/uniprot/uniprot/ObjectFactory.java:
	mkdir -p $(GENDIR)
	xjc ${XJCPROXY} -d $(GENDIR) "http://www.uniprot.org/docs/uniprot.xsd"


$(GENDIR)/gov/nih/nlm/ncbi/blast/ObjectFactory.java:
	 xjc ${XJCPROXY} -d $(GENDIR) -dtd -p gov.nih.nlm.ncbi.blast "http://www.ncbi.nlm.nih.gov/dtd/NCBI_BlastOutput.dtd"

clean:
	rm -rf $(GENDIR) bin/faToTwoBit 