package com.github.lindenb.genomehub;

import gov.nih.nlm.ncbi.blast.BlastOutput;
import gov.nih.nlm.ncbi.blast.Hit;
import gov.nih.nlm.ncbi.blast.Hsp;
import gov.nih.nlm.ncbi.gbseq.GBFeature;
import gov.nih.nlm.ncbi.gbseq.GBInterval;
import gov.nih.nlm.ncbi.gbseq.GBSeq;
import gov.nih.nlm.ncbi.gbseq.GBSet;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringReader;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.logging.Logger;
import javax.xml.bind.JAXBContext;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamSource;

import org.uniprot.uniprot.Uniprot;
import org.w3c.dom.Document;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;



public class GenomeHubGenerator
	{
	private static Logger LOG=Logger.getLogger("genomehub");
	private File baseDir=null;
	private PrintWriter genome_txt_out;
	private javax.xml.bind.Unmarshaller unmarshaller;
	private DocumentBuilder domBuilder=null;
	private DocumentBuilder domNSBuilder=null;
	private List<ReferenceSequence> referencesSequences=new ArrayList<ReferenceSequence>();
	
	private static interface Sequence
		{
		public int length();
		public Sequence getSubSequence(int start,int end);
		public int convertToReference(int pos);
		}
	
	private static class ReferenceSequence implements Sequence
		{
		public String name;
		private int size=0;
		
		public int length()
			{
			return this.size;
			}
		public int convertToReference(int pos)
			{
			return pos;
			}
		public Sequence getSubSequence(int start,int end)
			{
			return null;
			}
		}

	
	
	private static class Block
		{
		int start;
		int end;
		Block(int start,int end)
			{
			this.start=start;
			this.end=end;
			}
		Block()
			{
			this(-1,-1);
			}
		}
	
	public class BedRecord
		implements Comparable<BedRecord>
		{
		public String chrom;
		public int chromStart;
		public int chromEnd;
		@Override
		public int compareTo(BedRecord o)
			{
			int i=chrom.compareTo(o.chrom);
			if(i!=0) return i;
			i=chromStart-o.chromStart;
			if(i!=0) return i;
			i=chromEnd-o.chromEnd;
			if(i!=0) return i;
			return 0;
			}
		}
	
	public class ExtendedBedRecord
	extends BedRecord	
		{
		List<Block> blocks=new ArrayList<Block>();
		String name=null;
		int score=-1;
		char strand='+';
		int thickStart=-1;
		int thickEnd=-1;
		String itemRgb="";
		public int getBlockCount()
			{
			return blocks.size();
			}
		public int[] getBlockSizes()
			{
			int i=0;
			int L[]=new int[getBlockCount()];
			for(Block b:this.blocks) L[i++]=b.end-b.start;
			return L;
			}

		public int[] getBlockStarts()
			{
			int i=0;
			int L[]=new int[getBlockCount()];
			for(Block b:this.blocks) L[i++]=b.start;
			return L;
			}

		}

	
	private GenomeHubGenerator() throws Exception
		{
		JAXBContext jaxbCtxt=JAXBContext.newInstance(
			  	"com.github.lindenb.genomehub:"+
				"gov.nih.nlm.ncbi.blast:"+
				"gov.nih.nlm.ncbi.gbseq:"+
			  	"org.uniprot.uniprot"
			  	);
		this.unmarshaller=jaxbCtxt.createUnmarshaller();
		
		DocumentBuilderFactory dbf=DocumentBuilderFactory.newInstance();
		dbf.setValidating(false);
		this.domBuilder=dbf.newDocumentBuilder();
		EntityResolver er=new EntityResolver() {
			@Override
			public InputSource resolveEntity(String publicId, String systemId)
					throws SAXException, IOException {
				return new InputSource(new StringReader(""));
			}
			};
		this.domBuilder.setEntityResolver(er);
		dbf.setNamespaceAware(true);
		this.domNSBuilder=dbf.newDocumentBuilder();
		this.domNSBuilder.setEntityResolver(er);
		}
	
	private void exec(String args[]) throws Exception
		{
		Process proc=Runtime.getRuntime().exec(args);
		int ret0=proc.waitFor();
		if(ret0!=0)
			{
			LOG.severe("error:"+Arrays.asList(args));
			System.exit(-1);
			}
		}
	
	private void faToTwoBit(Genome g) throws Exception
		{
		LOG.info("faToTwoBit for "+g.getId());
		String twoBit=g.getFasta();
		int dot=twoBit.lastIndexOf('.');
		if(dot!=-1) twoBit=twoBit.substring(0, dot);
		twoBit+=".2bit";
		
		String args[]=new String[]{
				"faToTwoBit",
				"-noMask","-stripVersion",
				new File(this.baseDir,g.getFasta()).getPath(),
				new File(this.baseDir,twoBit).getPath()
				};
		exec(args);
		
		this.genome_txt_out.println("twoBitPath "+twoBit);
		}
	
	private Document downloadToDom(String url)throws Exception
		{
		LOG.info("get "+url);
		Document dom=this.domBuilder.parse(url);
		return dom;
		}
	
	private GBSet downloadGbSet(String id) throws Exception
		{
		String uri="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&rettype=gb&retmode=xml&id="+
				  URLEncoder.encode(id,"UTF-8");
		 Document dom=downloadToDom(uri);
		return this.unmarshaller.unmarshal(new DOMSource(dom), GBSet.class).getValue();
		}
	
	
	private void makeblastdb(Genome g) throws Exception
		{
		LOG.info("makeblastdb for "+g.getId());
		String args[]=new String[]{
				"makeblastdb",
				"-dbtype","nucl",
				"-in",new File(this.baseDir,g.getFasta()).getPath()
				};
		exec(args);
		
		}
	
	private void writeFasta(String name,String seq,File out)
		throws IOException
		{
		LOG.info("writing seq fasta "+name+" to "+out);
		PrintWriter pw=new PrintWriter(out);
		pw.print(">"+name);
		for(int i=0;i< seq.length();++i)
			{
			if(i%60==0) pw.println();
			pw.print(seq.charAt(i));
			}
		pw.println();
		pw.flush();
		pw.close();
		}
	
	private BlastOutput blast(Genome g,File fileIn)throws Exception
		{
		LOG.info("blasting "+fileIn);
		File tmpOut=File.createTempFile("tmp.", ".blast.xml");
		tmpOut.deleteOnExit();
		String args[]=new String[]{
				"blastn",
				"-query",fileIn.getPath(),
				"-db",new File(this.baseDir,g.getFasta()).getPath(),
				"-outfmt","5",
				"-out",tmpOut.getPath()
			};
		exec(args);
		Document dom=this.domBuilder.parse(tmpOut);
		BlastOutput bo=this.unmarshaller.unmarshal(dom,BlastOutput.class).getValue();
		tmpOut.delete();
		return bo;
		}
	
	
	private ExtendedBedRecord createGBFeature(GBFeature feat)
		{
		ExtendedBedRecord bed=new ExtendedBedRecord();
		bed.name=feat.getGBFeatureKey();
		for(GBInterval interval:feat.getGBFeatureIntervals().getGBInterval())
			{
			int fStart;
			int fEnd;
			if(interval.getGBIntervalPoint()!=null)
				{
				fEnd=Integer.parseInt(interval.getGBIntervalPoint());
				fStart=fEnd-1;
				}
			else
				{
				fStart=Integer.parseInt(interval.getGBIntervalFrom())-1;
				fEnd=Integer.parseInt(interval.getGBIntervalTo());
				if(fStart>fEnd)
					{
					fStart=Integer.parseInt(interval.getGBIntervalTo())-1;
					fEnd=Integer.parseInt(interval.getGBIntervalFrom());
					}
				}
			Block block=new Block(fStart, fEnd);
			bed.blocks.add(block);
			}
		return bed;
		}
	private void handleUniprot(Genome g,String id)throws Exception
		{
		String uri="http://www.uniprot.org/uniprot/"+
				  URLEncoder.encode(id,"UTF-8")+".xml";
		 Uniprot uniprot= this.unmarshaller.unmarshal(new DOMSource(this.domNSBuilder.parse(uri)), Uniprot.class).getValue();

		
		}
	
	private void handleNucleotide(Genome g,String id)throws Exception
		{
		Set<String> ignoreQuals=new HashSet<String>();
		ignoreQuals.add("source");
		GBSet gb=downloadGbSet(id);
		if(gb.getGBSeq().size()!=1) return;
		GBSeq gbSeq= gb.getGBSeq().get(0);
		File tmpIn=File.createTempFile("tmp.", ".fa");
		tmpIn.deleteOnExit();
		writeFasta(
				gbSeq.getGBSeqAccessionVersion(),
				gbSeq.getGBSeqSequence(),
				tmpIn
				);
		BlastOutput bo=blast(g,tmpIn);
		for(GBFeature feat:gbSeq.getGBSeqFeatureTable().getGBFeature())
			{
			if(ignoreQuals.contains(feat.getGBFeatureKey())) continue;
			LOG.info(feat.getGBFeatureKey());
			int featureLen=0;
			
			for(GBInterval interval:feat.getGBFeatureIntervals().getGBInterval())
				{
				int fStart;
				int fEnd;
				if(interval.getGBIntervalPoint()!=null)
					{
					fEnd=Integer.parseInt(interval.getGBIntervalPoint());
					fStart=fEnd-1;
					}
				else
					{
					fStart=Integer.parseInt(interval.getGBIntervalFrom())-1;
					fEnd=Integer.parseInt(interval.getGBIntervalTo());
					if(fStart>fEnd)
						{
						LOG.info("TODO#############");
						}
					}
				featureLen+=(fEnd-fStart);
	
				for(Hit h:bo.getBlastOutputIterations().getIteration().get(0).getIterationHits().getHit())
					{
					ExtendedBedRecord bed=new ExtendedBedRecord();
					System.err.println("hitd def:"+h.getHitDef());
					bed.chrom=h.getHitDef();
					bed.name=gbSeq.getGBSeqAccessionVersion()+":"+feat.getGBFeatureKey();
					
					for(Hsp hsp:h.getHitHsps().getHsp())
						{
						int hStart=Integer.parseInt(hsp.getHspHitFrom())-1;
						int hEnd=Integer.parseInt(hsp.getHspHitTo());
						if(hStart>hEnd)
							{
							LOG.info("TODO#############");
							}
						int qStart=Integer.parseInt(hsp.getHspQueryFrom())-1;
						int qEnd=Integer.parseInt(hsp.getHspQueryTo());
						if(qStart>qEnd)
							{
							LOG.info("TODO#############");
							}
						if(qStart>=fEnd) continue;
						if(qEnd<=fStart) continue;
						while(qStart<fStart)
							{
							hStart++;
							qStart++;
							}
						while(qEnd>fEnd)
							{
							hEnd--;
							qEnd--;
							}
						LOG.info(""+qStart+"/"+qEnd+" vs "+hStart+"/"+hEnd);

						Block block=new Block(hStart, hEnd);
						bed.blocks.add(block);
						}
					if(bed.getBlockCount()==0) continue;
					bed.score=0;
					LOG.info("Ok got bed");
					}
				
				}
			
			}
		tmpIn.delete();
		}
	
	private void make(Genome g) throws Exception
		{
		LOG.info("making "+g.getId());
		this.referencesSequences.clear();
		this.genome_txt_out.println("genome "+g.getId());

		FileReader fr=new FileReader(new File(this.baseDir,g.getFasta()));
		ReferenceSequence last=null;
		int c;
		while((c=fr.read())!=-1)
			{
			if(c=='>')
				{
				last=new ReferenceSequence();
				this.referencesSequences.add(last);
				while((c=fr.read())!=-1 && c!='\n') last.name+=(char)c;
				continue;
				}
			else if(Character.isLetter(c))
				{
				last.size++;
				}
			}
		fr.close();
		
		
		faToTwoBit(g);
		makeblastdb(g);
		File tmp1=File.createTempFile("_tmp", ".xml");
		tmp1.deleteOnExit();
		for(Nucleotide acn:g.getDna())
			{
			
			}	
		handleNucleotide(g,"J04346");
		handleNucleotide(g,"170791374");
		tmp1.delete();
		
		this.genome_txt_out.println();
		}
	
	private void run(String[] args) throws Exception
		{
		int optind=0;
		while(optind<args.length)
			{
			if(args[optind].equals("-h"))
				{
				return;
				}
			else if(args[optind].equals("-L"))
				{
				
				}
			else if(args[optind].equals("--"))
				{
				optind++;
				break;
				}
			else if(args[optind].startsWith("-"))
				{
				System.err.println("Unnown option: "+args[optind]);
				return;
				}
			else
				{
				break;
				}
			++optind;
			}
		if(optind+1!=args.length)
			{
			LOG.severe("expected only one parameter");
			System.exit(-1);
			}
		
		File xml= new File(args[optind]);
		LOG.info("reading "+xml);
		this.baseDir=xml.getParentFile();
		GenomeHub config=this.unmarshaller.unmarshal(new StreamSource(xml),GenomeHub.class).getValue();
		
		PrintWriter pw= new PrintWriter(new File(this.baseDir,"hub.txt"));
		pw.println("hub "+config.getId());
		pw.println("shortLabel "+config.getName());
		pw.println("longLabel "+config.getName());
		pw.println("genomesFile genomes.txt");
		pw.println("email "+config.getEmail());
		pw.flush();
		pw.close();
		
		this.genome_txt_out = new PrintWriter(new File(this.baseDir,"genomes.txt"));
		for(Genome g:config.getGenome())
			{
			make(g);
			}
		this.genome_txt_out.flush();
		this.genome_txt_out.close();
		LOG.info("done");
		}

	
	public static void main(String[] args) throws Exception
		{
		new GenomeHubGenerator().run(args);
		}
	}
