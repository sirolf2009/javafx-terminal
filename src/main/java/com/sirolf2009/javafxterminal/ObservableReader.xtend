package com.sirolf2009.javafxterminal

import io.reactivex.subjects.Subject
import java.io.IOException
import java.io.Reader
import io.reactivex.subjects.ReplaySubject
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors class ObservableReader extends Reader {
	
	val Reader reader
	val Subject<Character> characters
	
	new(Reader reader) {
		this.reader = reader
		this.characters = ReplaySubject.create()
	}
	
	override close() throws IOException {
		reader.close()
	}
	
	override read(char[] cbuf, int off, int len) throws IOException {
		val code = reader.read(cbuf, off, len)
		(off ..< len).map[cbuf.get(it)].forEach[characters.onNext(it)]
		return code
	}
	
}