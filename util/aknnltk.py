#! /usr/bin/python3 -uW all
# -*- coding: utf-8 -*-
##
# Corpus reader for Akoma Ntoso documents.
#
# import nltk.text, aknnltk
# t = nltk.text.Text(aknnltk.AKNCorpusReader('/tmp/openlaw-test', '.*\.xml').words('pen.xml'))
# t.plot(20)
#

from nltk.tokenize import WordPunctTokenizer
from nltk.corpus.reader.xmldocs import XMLCorpusReader

class AKNCorpusReader(XMLCorpusReader):
	"""
	Corpus reader for Akoma Ntoso documents.

	"""
	def __init__(self, root, fileids):
		XMLCorpusReader.__init__(self, root, fileids)
	
	def xml(self, fileid=None):
		return XMLCorpusReader.xml(self, fileid)
	
	def words(self, fileid=None):
		"""
		Returns all of the words and puncuation symbols in the specified file
		that were in 'section//p' text nodes.
		"""
		elt = self.xml(fileid).iterfind('.//section//p')
		word_tokenizer = WordPunctTokenizer()
		return [val for subl in [word_tokenizer.tokenize(nodetext) for nodetext in [''.join(el.itertext()) for el in elt]] for val in subl]
	
	def raw(self, fileids=None):
		return XMLCorpusReader.raw(self, fileids)

