###########################################################################################
#Used to load packages. If the packages is not exist, it will download packages automatically

pkgLoad <- function(package, repos = "http://cran.csie.ntu.edu.tw/") {
    if (!require(package, character.only = TRUE)) {
        install.packages(package, dep=TRUE, repos = repos)
        if(!require(package, character.only = TRUE)) stop("Package not found")
    }
    library(package, character.only=TRUE)
}

pkgLoad("topicmodels")
pkgLoad("tm")
pkgLoad("tmcn", "http://R-Forge.R-project.org")
pkgLoad("jiebaR")
pkgLoad("RJSONIO")

pkgLoad("ggplot2")
pkgLoad("gridExtra")
pkgLoad("wordcloud")
pkgLoad("LDAvis")

###########################################################################################
#Main function.

PTT_LDA <- function(source_dir, article_num = NULL, load_push = FALSE, segment_user_dict_path = NULL, k = 3, show_num = 30) {

    message("Start.")
    #Load article from JSON file.
    message("Load Raw Data.")

    article_list <- list.files(source_dir)
    article_num <- if(is.null(article_num) || article_num > length(article_list)) length(article_list) else article_num

    content_list <- NULL

    for(article_no in c(1:article_num)) {

        article_id <- article_list[article_no]
        article_path <- paste(source_dir, "/", article_id, "/", article_id, ".json", sep = "")

        if(!file.exists(article_path)) next

        message(article_id)
        article <- fromJSON(article_path)

        content_list <- c(content_list, article$Content)

        push_list <- list.files(paste(source_dir, "/", article_id, sep = ""))
        push_num <- if(load_push) length(push_list) else 0

        if(push_num > 1) {
            for(push_no in c(1:(push_num - 1))) {

                push_path <- paste(article_id, "/", push_list[push_no], sep ="")
                message(push_path)
                push <- fromJSON(paste(source_dir, "/",  push_path, sep = ""))

                content_list <- c(content_list, push[1])

            }
        }

    }


    #Create Corpus.
    message("Create Corpus.")

    ptt_corpus <- Corpus(VectorSource(content_list))


    #Pre-Process.
    message("Start Pre-process.")

    ptt_corpus <- tm_map(ptt_corpus, removePunctuation)
    ptt_corpus <- tm_map(ptt_corpus, removeNumbers)
    ptt_corpus <- tm_map(ptt_corpus, function(word) {
        gsub("[A-Za-z0-9]", "", word)
    })


    #Segmentation.
    message("Segmentation.")

    jieba <- if(is.null(segment_user_dict_path)) worker() else worker(user = segment_user_dict_path)
    ptt_corpus <- tm_map(ptt_corpus, segment, jiebar = jieba)


    #Speech Tagging and Extract Nouns.
    message("Speech Tagging.")

    flag <- 0
    n <- 1
    while(flag != 1) {

        if(n == length(ptt_corpus)) flag <- 1
        if(length(ptt_corpus[[n]]) == 0) ptt_corpus[[n]] <- NULL else n <- n + 1

    }

    tagger <- worker("tag")
    ptt_corpus <- tm_map(ptt_corpus, function(word) {
        speech_tags <- tagging(word, tagger)
        speech_tags <- speech_tags[grepl("[*n*]", names(speech_tags))]
    })


    #Finsh Pre-Process.
    message("Finsh Pre-Process.")

    ptt_corpus <- tm_map(ptt_corpus, PlainTextDocument)

    for(n in c(1:length(ptt_corpus))) {
        meta(ptt_corpus[[n]], "id") <- n
    }

    ptt_corpus <- tm_map(ptt_corpus, PlainTextDocument)

    #Create Document-Term Matrix.
    dtm <- DocumentTermMatrix(ptt_corpus)
    dtm <- dtm[rowSums(as.matrix(dtm)) > 0, ]

    #Limtit length of terms at least longer 2.
    #dtm <- DocumentTermMatrix(ptt_corpus, control = list(wordLengths = c(2, Inf)))


    #Remove spare terms if needed.
    #dtm_pruned <- removeSparseTerms(dtm, 0.01)


    #Calculate term frequency.
    message("Calculate term frequency.")

    #findFreqTerms(dtm, lowfreq = 150)
    term_freq <- sort(colSums(as.matrix(dtm)), decreasing=TRUE)

    term_freq_top <- data.frame(Term = c(1:show_num), Freq = c(1:show_num))
    term_freq_top$Term <- names(head(term_freq, show_num))
    term_freq_top$Freq <- head(term_freq, show_num)
    #associations_top <- findAssocs(dtm, term_freq_top$Term, 0.5)


    #Create plot of word freq top n.
    plot <- ggplot(term_freq_top, aes(Term, Freq))    
    plot <- plot + geom_bar(stat="identity")   
    plot <- plot + theme(axis.text.x = element_text(angle = 45, hjust = 1, size = rel(1.5)), axis.text.y = element_text(size = rel(1.5)), axis.title = element_text(size = rel(2)))

    dir.create("Result", showWarnings = FALSE)
    png(filename = "Result/Term_Freq_Top.png", width = 960, height = 540, units = "px")
    plot(plot)
    dev.off()


    #Create Word Cloud.
    message("Create Word Cloud.")

    png(filename = "Result/Word_Cloud.png", width = 540, height = 540, units = "px")
    wordcloud(names(term_freq), term_freq, min.freq = 50, scale=c(5, .1), colors=brewer.pal(6, "Dark2"))
    dev.off()


    #LDA
    message("Start LDA.")

    lda_model <- LDA(dtm, k = k)
    topic_terms_top <- terms(lda_model, show_num)

    #Create plot of top n word in every topic
    df <- data.frame(x = 1:10, y = 1:10)

    topic_terms_top <- as.matrix(data.frame(No = c(1:length(topic_terms_top[,1])), topic_terms_top))

    theme <- ttheme_default(core = list(fg_params=list(cex = 2.0)), colhead = list(fg_params=list(cex = 2.5)), rowhead = list(fg_params=list(cex = 3.0)))
	plot <- ggplot(df, aes(x, y)) + geom_blank() + theme_bw()
    plot <- plot + annotation_custom(tableGrob(topic_terms_top, theme = theme), xmin = 0, xmax = Inf, ymin = -Inf, ymax = 10)
	plot <- plot + theme(
		axis.line=element_blank(),
		axis.text.x=element_blank(),
		axis.text.y=element_blank(),
		axis.ticks=element_blank(),
		axis.title.x=element_blank(),
		axis.title.y=element_blank(),
		legend.position="none",
		panel.background=element_blank(),
		panel.border=element_blank(),
		panel.grid.major=element_blank(),
		panel.grid.minor=element_blank(),
		plot.background=element_blank()
	)

    png(filename = "Result/Topic_Word_Top.png", width = 720, height = 720, units = "px")
    plot(plot)
    dev.off()


    #LDAVis
    message("Start LDA visualization.")

    phi <- as.matrix(posterior(lda_model)$terms)
    theta <- as.matrix(posterior(lda_model)$topics)
    vocab <- colnames(phi)
    doc_length <- as.vector(rowSums(as.matrix(dtm)))
    term_frequency <- as.vector(colSums(as.matrix(dtm)))

    ldavis_json <- createJSON(phi = phi, theta = theta, vocab = vocab, doc.length = doc_length, term.frequency = term_frequency, R = show_num)
    serVis(ldavis_json, out.dir = "Result/LDAvis/", open.browser = FALSE)


    message("All Finshed.")

}

#######################################################################################################################3
#Main

source_dir <- "Samples/"
article_num <- 30
load_push = FALSE
segment_user_dict_path <- "PTT_Extension_Terms"
k = 3
show_num = 20

PTT_LDA(source_dir = source_dir, article_num = article_num, load_push = load_push, segment_user_dict_path = segment_user_dict_path, k = k, show_num = show_num)
