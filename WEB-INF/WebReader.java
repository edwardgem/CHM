import java.net.*;
import java.io.*;
import java.util.*;
import oct.omm.common.*;
import oct.omm.servapp.*;

public class WebReader
{
	static int c_newParagraph;
	static int c_lineBreak;
	static boolean c_bNoSend = false;
	static final int LINE_LENGTH = 60;
	static final String URL_ADDR  = "http://sz.91160.com/dep/show/depid-4230.html";
	static final String COPYRIGHT = "2001 RBC Ministries--Grand Rapids, MI 49555";
	static String sender;
	static String host;
	static final String	RECEIPIENT	= "MailServe@eGuanxi.com";

	public static void main(String[] args)
		throws Exception
	{
		if (args.length == 0)
			sender = "johnnyl@eGuanxi.com";
		else
			sender = args[0];

		if (args.length < 2)
			host = "10.10.10.50";
		else
			host = args[1];

		if (args.length > 3)
			c_bNoSend = true;

		URL daily = new URL(URL_ADDR);
		URLConnection db = daily.openConnection();
		BufferedReader in = new BufferedReader(
							   new InputStreamReader(
							   db.getInputStream()));

		String inputLine;
		StringBuffer sBuf = new StringBuffer();
		while ((inputLine = in.readLine()) != null)
		{
			int index = inputLine.lastIndexOf("&#150;");
			if (index >= 0)
				inputLine = inputLine.substring(0,index) + "--" + inputLine.substring(index+6);
			sBuf.append(inputLine);
		}
		in.close();
		System.out.println(sBuf.toString());
	}

	static void strip(String sBuf)
	{
		int i;
		StringBuffer res = new StringBuffer();
		res.append("Our Daily Bread\n");

		// date
		String s = "Our Daily Bread</a>";
		i = sBuf.indexOf(s);
		i += s.length();
		i = skipTag(sBuf, i);
		i = copyTillTag(res, sBuf, i);
		res.append("\n\n");

		// today's theme
		i = sBuf.indexOf("<h2>", i);
		i += 4;				// skip <h2>
		i = copyTillTag(res, sBuf, i);
		res.append("\n");

		// scripture reference
		s = "Read: ";
		i = sBuf.indexOf(s, i);
		i = skipTag(sBuf, i+s.length());
		res.append('(');
		res.append(s);
		i = copyTillTag(res, sBuf, i);
		res.append(")\n\n");

		// theme verse
		i = skipTags(sBuf, i);
		i = copyTillTag(res, sBuf, i);
		res.append("\n\n");

		// body
		i = skipTags(sBuf, i);
		int j = sBuf.indexOf("<center>", i);
		i = copyTill(res, sBuf, i, j);
		res.append("\n\n");

		// poem
		i = skipTags(sBuf, i);
		j = sBuf.indexOf("</center>");
		i = copyTill(res, sBuf, i, j);

		// copyright statement
		res.append(COPYRIGHT);

		// print buffer only
		if (c_bNoSend)
		{
			System.out.println(res.toString());
			return;
		}
	}

	static int skipTag(String s, int idx)
	{
		int i = idx;
		char c;
		do
		{	// skip white space
			c = s.charAt(i++);
		} while (isWhite(c));
		i--;

		while (s.charAt(i++) != '<');
		if (s.substring(i,i+2).equals("p>"))
			c_newParagraph++;
		else if (s.substring(i,i+3).equals("br>"))
			c_lineBreak++;
		while (s.charAt(i++) != '>');
		return i;	// return index of char on right of '>'
	}

	static int skipTags(String s, int idx)
	{
		while (true)
		{
			idx = skipTag(s, idx);
			char c;
			do
			{	// skip white space
				c = s.charAt(idx++);
			} while (isWhite(c));
			idx--;
			if (c != '<')
				break;
		}
		return idx;	// return index of char on right of '>' (non-white)
	}

	static boolean isWhite(char c)
	{
		return ((c == ' ') || (c == '\t') || (c == '\n'));
	}

	static int copyTillTag(StringBuffer targetB, String src, int idx)
	{
		// return pos of "<"
		int end = src.indexOf("<", idx);
		if (end < 0)
			end = src.length();
		appendLine(targetB, src, idx, end, LINE_LENGTH);
		return end;
	}

	static int copyTill(StringBuffer targetB, String src, int beg, int end)
	{
		// copy from beg to end-1 skipping all tag in between
		int i = beg;
		int idx;
		while (i < end)
		{
			// copy between tags
			idx = src.indexOf("<", i);
			if ((idx < 0) || (idx > end))
			{
				// copy the last batch and leave
				targetB.append(src.substring(i, end));
				break;
			}
			appendLine(targetB, src, i, idx, LINE_LENGTH);
			c_newParagraph = 0;
			c_lineBreak = 0;
			i = skipTags(src, idx-1);
			if (c_newParagraph > 0)
				targetB.append("\n");
			while (c_newParagraph-- > 0)
				targetB.append("\n");
			while (c_lineBreak-- > 0)
				targetB.append("\n");
		}
		return end;
	}

	static void appendLine(StringBuffer targetB, String src,
		int beg, int end, int lineLength)
	{
		int i = beg, j;
		while (end - i > lineLength)
		{
 			j = src.indexOf(" ", i+lineLength);
			if (j > end)
				break;
			targetB.append(src.substring(i, j));
			targetB.append("\n");
			i = j+1;
		}
		targetB.append(src.substring(i, end));
	}


	public static String replaceAll(String in, String pattern, String newPattern)
		throws OmsException
	{
 			int i,j, k=0;
			int len = newPattern.length();
			String out = "";
			while ((i = in.indexOf(pattern, k)) != -1)
			{
				j = len + i;
				out = out + in.substring(k, i) + newPattern;
				k = j + 1;
			}

			return out + in.substring(k, in.length());
	}

}