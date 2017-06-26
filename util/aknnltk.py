#! /usr/bin/python3 -uW ignore
# -*- coding: utf-8 -*-
##
# Corpus reader for Akoma Ntoso documents.
#

from nltk.tokenize import word_tokenize, sent_tokenize
from nltk.corpus.reader.xmldocs import XMLCorpusReader
import unittest

class AKNCorpusReader(XMLCorpusReader):
	"""
	Corpus reader for Akoma Ntoso documents.

	"""
	def __init__(self, root, fileids):
		XMLCorpusReader.__init__(self, root, fileids)

	def words(self, fileid=None):
		"""
		Returns a list of strings representing word tokens.
		"""
		return (val for subl in self.sents(fileid) for val in subl)

	def sents(self, fileid=None):
		"""
		Returns a list of lists of strings representing word tokens with
		sentence boundaries intact.
		"""
		return (word_tokenize(sent) for sent in self._sents(fileid))

	def _sents(self, fileid=None):
		"""
		Returns all of the sentences in the specified file.

		Returns all of the Akoma Ntoso '//section//content/p' text nodes
		in the specified file.
		"""
		els = self.xml(fileid).iterfind('.//{http://docs.oasis-open.org/legaldocml/ns/akn/3.0/WD17}section//{http://docs.oasis-open.org/legaldocml/ns/akn/3.0/WD17}content')
		paras = (''.join(el.itertext()) for el in els)
		return (val for subl in (sent_tokenize(p) for p in paras) for val in subl)

class MyTest(unittest.TestCase):
	def test(self):
		from nltk.text import Text
		corpus = AKNCorpusReader('/tmp/openlaw-test/', '.*\.xml')
		t1 = Text(corpus.words('akn-usc18.xml'))
		t1.concordance('murder',lines=float('inf'))
#		t1.plot(20)
		t2 = Text(corpus.words('PEN.xml'))
		t2.concordance('murder',lines=float('inf'))
#		t2.plot(20)

if __name__ == "__main__":
	unittest.main()

