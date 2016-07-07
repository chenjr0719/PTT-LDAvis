# PTT-LDAvis

Using LDAvis to visualize the LDA model of PTT.

Live Demo: http://chenjr-jacob.no-ip.org:8080/LDAvis/

## What is PTT?

**PTT** is the biggest BBS site in Taiwan.

It is also a good place to gather information, which means: I can collect information and take analysis like Text Mining, Topic models, and others.

## What is LDA and LDAvis

**LDA** is a kind of topic model which discovering the abstract "topics" that occur in a collection of documents.

It can also represent the trend of documents or news.

**LDAvis** is a package for R, it aims to help users interpret the topics in a topic model on an interactive web-based visualization.

## Requirement

**PTT-LDAvis** is built by R and using following packages:

* topicmodels
* tm
* tmcn
* jiebaR
* RJSONIO
* ggplot2
* gridExtra
* wordcloud
* LDAvis

This script will use **pkgLoad** to download package if it doesn't exist.

But **topicmodels** may not install successfully.

In Ubuntu, you can use this command to solve this problem:

```s
sudo apt-get install gsl-bin libgsl0-dev
```


## Data Sources

The data source of **PTT-LDAvis** is from .json files.

They should look like this (at least they have to include the content item):

```s
article = {
  'Board': board,
  'Article_Title': title,
  'Article_ID': article_id,
  'Author': author,
  'Time': publish_time,
  'Push_num': push_count,
  'Bad_num': bad_count,
  'Arrow_num': arrow_count,
  'Content': content
}
```

and

```s
push = {
  'Tag': push_tag,
  'User': push_user,
  'Time': push_time,
  'Content': push_content,
  'ID': article_id + '_' + str(push_id)
}
```

You can use my sample data or my **PTT-Crawler** to crawling from PTT.

## How to Use?

There are a few parameters of **PTT-LDAvis**:

* source_dir: The path of source data.
* article_num: The number of article(including pushes) you want to use. (Default: the numbers in source_dir)
* load_push: If you want to use pushes as your data, set it to TRUE. If not, set as FALSE. (Default: FALSE)
* segment_user_dict_path: The path of user defined dictionary. You can also add new terms yourself. (Default: NULL)
* k: The number of topics you want LDA to separate into.
* show_num: This number will be used at showing term frequency, the top term of topics, and LDAvis.

And, run the command in R:

```s
source("PTT_LDAvis.R")
```

## Output

**PTT-LDAvis** will output some data:

* Term_Freq_Top.png: Showing the term frequency of top n(show_num).
* Topic_Word_Top.png: Showing the top n(show_num) term of topics.
* Word_Cloud.png: The word cloud.
* LDAvis: The result of LDA and visualization. Use index.html to check the result on browser.
