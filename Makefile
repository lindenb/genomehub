include config.mk
GENDIR=src/main/generated-sources/java
.PHONY:all clean generatecode

all: generatecode bin/faToTwoBit
	mkdir -p tmp
	javac -sourcepath src/main/java:$(GENDIR) -d tmp \
		src/main/java/com/github/lindenb/genomehub/GenomeHubGenerator.java \
		$(GENDIR)/gov/nih/nlm/ncbi/blast/ObjectFactory.java \
		$(GENDIR)/gov/nih/nlm/ncbi/gbseq/ObjectFactory.java \
		$(GENDIR)/com/github/lindenb/genomehub/ObjectFactory.java \
		$(GENDIR)/org/uniprot/uniprot/ObjectFactory.java
	java -Dhttp.proxyHost=${PROXYHOST}  -Dhttp.proxyPort=${PROXYPORT} \
		-cp tmp com.github.lindenb.genomehub.GenomeHubGenerator \
		data/genomehub.xml
	rm -rf tmp

bin/faToTwoBit : 
	mkdir -p $(dir $@)
	curl ${CURLPROXY} -o $@ "http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/$(notdir $@)"
	chmod +x $@

generatecode: $(GENDIR)/com/github/lindenb/genomehub/ObjectFactory.java \
			$(GENDIR)/org/uniprot/uniprot/ObjectFactory.java \
			$(GENDIR)/gov/nih/nlm/ncbi/blast/ObjectFactory.java \
			$(GENDIR)/gov/nih/nlm/ncbi/gbseq/ObjectFactory.java

$(GENDIR)/com/github/lindenb/genomehub/ObjectFactory.java : src/main/resources/xsd/genomehub.xsd
	mkdir -p $(GENDIR)
	xjc ${XJCPROXY} -d $(GENDIR) -p com.github.lindenb.genomehub $<

$(GENDIR)/org/uniprot/uniprot/ObjectFactory.java:
	mkdir -p $(GENDIR)
	xjc ${XJCPROXY} -d $(GENDIR) "http://www.uniprot.org/docs/uniprot.xsd"

$(GENDIR)/gov/nih/nlm/ncbi/gbseq/ObjectFactory.java:
		 xjc ${XJCPROXY} -d $(GENDIR) -dtd -p gov.nih.nlm.ncbi.gbseq "http://www.ncbi.nlm.nih.gov/dtd/NCBI_GBSeq.dtd"
	

$(GENDIR)/gov/nih/nlm/ncbi/blast/ObjectFactory.java:
	 xjc ${XJCPROXY} -d $(GENDIR) -dtd -p gov.nih.nlm.ncbi.blast "http://www.ncbi.nlm.nih.gov/dtd/NCBI_BlastOutput.dtd"

clean:
	rm -rf $(GENDIR) bin/faToTwoBit tmp