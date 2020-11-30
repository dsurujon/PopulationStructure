# Jakob Weiss, 11/29/2020

# aim: for the phylogeny of each adapted gene identified in the CIP and PEN experiments,
# plot the tree with ggtree, adding a heatmap showing susceptibility/resistance to the corresponding antibiotic

library(ggtree)
library(ggplot2)
library(plyr)

setwd('~/Desktop/College/TvO/PopStruct')

# load susceptibility data, strain name mapping
phenoData <- as.data.frame(readxl::read_xls('suscep_data.xls',skip = 1))
pg_map <- read.delim('PG_accessions.txt')

# map isolate IDs from susceptibility data to PGxxx strain names
phenoData <- phenoData[phenoData$`Isolates from (city)`=='Nijmegen',]
pgNames <- mapvalues(phenoData$Isolate_ID,
                     from = c(pg_map$acc,'Reference'),
                     to = c(pg_map$pg,'Reference'))
phenoData$Isolate_ID <- pgNames
names(phenoData)[1] <- 'id'
rownames(phenoData) <- pgNames
phenoData[,6:12] <- replace(phenoData[,6:12],
                            phenoData[,6:12]=='0',
                            'susceptible')
phenoData[,6:12] <- replace(phenoData[,6:12],
                            phenoData[,6:12]=='1',
                            'resistant')

# iterate through each gene tree for each antibiotic, plotting only if it has 5 or more tips
# (if plotting, map isolate IDs to PGxxx strain names)
colors <- c('susceptible'='lightblue','resistant'='darkorange')
for (abx in c('PEN','CIP')){
  setwd(paste('~/Desktop/College/TvO/PopStruct/',abx,sep=''))
  
  for (geneTree in Sys.glob('./trees/*.nwk_noquote')){
    tr <- read.tree(geneTree)
    if (length(tr$tip.label >= 5)){
      gcID <- strsplit(strsplit(geneTree,'/')[[1]][3],'.nwk')[[1]][1]
      
      tr$tip.label <- unlist(lapply(strsplit(tr$tip.label, '.gff'), '[[', 1))
      tr$tip.label <- mapvalues(tr$tip.label,
                           from = pg_map$acc,
                           to = pg_map$pg)
      
      p <- ggtree(tr, layout='circular') + geom_tiplab(align=T, linetype='dotted', linesize = 0.3, size=1.2) + ggtitle(gcID)
      if (abx=='PEN'){
        gheatmap(p, subset(phenoData,select=6),width = 0.1,offset = max(tr$edge.length)/4,font.size = 2,colnames_angle=90,hjust=0.5) + scale_fill_manual(values=colors)
      } else {
        gheatmap(p, subset(phenoData,select=11),width = 0.1,offset = max(tr$edge.length)/4,font.size = 2,colnames_angle=90,hjust=0.5) + scale_fill_manual(values=colors)
      }
      ggsave(paste('~/Desktop/College/TvO/PopStruct/geneOverlayPdfs/', abx, '/', gcID, '.pdf', sep=''),width=8,height=8,units='in')
    }
  }
}