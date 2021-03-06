library(rjson)
library(RCurl)
library(tm)
library(SnowballC)
j_file2 <-"./talks_art.json"
talks_art<-fromJSON(file=j_file2, method="C")
str(talks_art)
talks_art<-fromJSON(file=j_file2, method="C")
str(talks_art)
talk_names<-names(talks_art$talks[[16]]$talk)
talk_names
###Convertobject type
talks_art_list<-lapply(talks_art$talks, function(x){unlist(x)})
str(talks_art_list)
parse_talk_all<-data.frame()
df_parse_talk_all<-do.call("rbind", c(parse_talk_all, talks_art_list))
str(df_parse_talk_all)
length(df_parse_talk_all)
length(df_parse_talk_all[1,])
length(df_parse_talk_all[,1])

df_parse_talk_all<-data.frame(df_parse_talk_all)
str(df_parse_talk_all)

###Chage datatype of talk description
df_parse_talk_all$talk.description<-as.character(df_parse_talk_all$talk.description)
str(df_parse_talk_all$talk.description)

###Change names of variables
names(df_parse_talk_all)<-talk_names
str(df_parse_talk_all)


#####Term Clustering

###Convert object type
class(df_parse_talk_all$description)
ted_docs <- Corpus(VectorSource(df_parse_talk_all$description))
class(ted_docs)

###Pre-processing
ted_docs <- tm_map(ted_docs, tolower)
ted_docs <- tm_map(ted_docs, removeNumbers)
ted_docs <- tm_map(ted_docs, removePunctuation)
ted_docs <- tm_map(ted_docs, removeWords, stopwords("SMART"))
ted_docs <- tm_map(ted_docs, removeWords, "ted")

###Tokenizing
strsplit_space_tokenizer <- function(x) 
 unlist(strsplit(as.character(x), "[[:space:]]+")) 
token_docs<-(sapply(ted_docs$content, strsplit_space_tokenizer))
token_docs<-(sapply(token_docs, function(x){gsub(" ","", x)}))
token_freq<-table(unlist(token_docs))
summary(data.frame(token_freq)$Freq)

###Stemming
stem_docs <- sapply(token_docs, stemDocument)
stem_freq<-table(unlist(stem_docs))
summary(data.frame(stem_freq)$Freq)

df_stem_freq<-data.frame(stem_freq)
str(df_stem_freq)


###Term-Doc Matrix with Stemming
class(stem_docs)
stem_docs <- Corpus(VectorSource(stem_docs))
class(stem_docs)

###term weight: TfIDF
ted_tdm <- TermDocumentMatrix(stem_docs,
                              control = list(removePunctuation = TRUE,
                                             weighting=weightTfIdf,
                                             stopwords = TRUE))

inspect(ted_tdm[1,])


#####Hierachical Clustering: Term Clustering
###Remove sparse terms
ted_tdm_sparse <- removeSparseTerms(ted_tdm, sparse = 0.90)
ted_tdm_sparse$nrow
ted_tdm<-ted_tdm_sparse

###Convert to matrix
ted_m <- as.matrix(ted_tdm)

###Calculate similarity
###dist {stats} Distance Matrix Computation
###scale {base} Scaling and Centering of Matrix-like Objects
distMatrix<- dist(scale(ted_m))

###Execute hierarchial clustering
###hclust {stats} Hierarchical Clustering
###method=c("single", complete", "average", "mcquitty", "median, "centroid", "ward.D", "ward.D2)
fit <- hclust(distMatrix, method="ward.D")


plot(fit)
rect.hclust(fit, k=8)

###Save the dendrogram as PNG image file
png("./dendrogram_sparse_art_wd_k8.png", width = 1200, height=600)
plot(fit)
###k= number of clusters
rect.hclust(fit, k=8)
dev.off()

###Assign a cluster to a term
###cutree {stats} Cut a Tree into Groups of Data
###k= number of clusters
groups <- cutree(fit, k=8)
df_groups <- data.frame(groups)
str(df_groups)
df_groups$KWD <- rownames(df_groups)
str(df_groups)

###Write the clustering result to text file
write.table(df_groups, "./tc_result_art_wd_k8.txt", row.names=FALSE, col.names=TRUE, sep="\t")
