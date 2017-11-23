////////////////////////////////////////////////////
//	Copyright (c) 2017, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	ObdAnalytics.java
//	Author:	ECC
//	Date:	04/20/17
//	Description:
//		Process data and plot charts for Big Data Analytics.
//
//	Modification:
//
////////////////////////////////////////////////////////////////////

package mod.bots;

import java.awt.Color;
import java.awt.Font;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Random;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartUtilities;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.IntervalMarker;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.plot.XYPlot;
import org.jfree.data.xy.IntervalXYDataset;
import org.jfree.data.xy.XYDataset;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;
import org.jfree.ui.Layer;
import org.jfree.ui.RectangleAnchor;
import org.jfree.ui.TextAnchor;

import oct.pmp.exception.PmpException;
import util.Util;

public class ObdAnalytics {
	static final private char COMMA				= ',';
	static final private char EOL				= '@';
	
	static final private Double dNULL			= -99999.0;
	
	static final private String SHOW_FILE_PATH	= Util.getPropKey("pst", "SHOW_FILE_PATH");
	static final private String URL_FILE_PATH	= Util.getPropKey("pst", "URL_FILE_PATH");
	
	static private Random rand					= new Random(new Date().getTime());
	static private int RAND_MAX					= Integer.MAX_VALUE;
	static private int RAND_MIN					= Integer.MAX_VALUE - 100000;
	
	static private SimpleDateFormat df = new SimpleDateFormat ("yyyy-MM-dd");

    public static String createHistogram(String inputData, String[] header, String colName, String chartTitle)
    	throws PmpException
    {
		// produce a histogram
    	String msg;
		String [] colArr = extractColumn(inputData, header, colName);
		if (colArr == null) {
			msg = "Histogram column [" + colName + "] not found in data.";
			throw new PmpException(msg);
		}
		
		int randNumber = rand.nextInt(RAND_MAX - RAND_MIN + 1) + RAND_MIN;
		String fName = "Hist_" + randNumber + ".png";
		//File fout = new File(SHOW_FILE_PATH + "/" + fName);
		IntervalXYDataset xyDataset = createHistogramDataset(colArr, colName, 100.0);
		JFreeChart chart = createHistChart(xyDataset, colName, chartTitle);
        try {
    		FileOutputStream fos = new FileOutputStream(SHOW_FILE_PATH + "/" + fName);

    		ChartUtilities.writeScaledChartAsPNG(fos, chart, 800, 500, 2, 2);
		} catch (IOException e) {
			msg = "Failed to create Histogram.";
			throw new PmpException(msg);
		}
        
        fName = URL_FILE_PATH + "/" + fName;
        return fName;
	}
    
    public static String createScattergram(String inputData, String [] header,
    		String colName1, String colName2, String dotLabel, String chartTitle)
    	throws PmpException
    {
		// produce a scattergram
    	String msg;
		String [] colArr1 = extractColumn(inputData, header, colName1);
		if (colArr1 == null) {
			msg = "Scattergram column [" + colName1 + "] not found in data.";
			throw new PmpException(msg);
		}

		String [] colArr2 = extractColumn(inputData, header, colName2);
		if (colArr2 == null) {
			msg = "Scattergram column [" + colName2 + "] not found in data.";
			throw new PmpException(msg);
		}
		
		// handle age calculation and translation
		if (colName1.toLowerCase().contains("birthday")) {
			colName1 = "Age";
			colArr1 = getAge(colArr1);
		}
		else if (colName2.toLowerCase().contains("birthday")) {
			colName2 = "Age";
			colArr2 = getAge(colArr2);
		}

		int randNumber = rand.nextInt(RAND_MAX - RAND_MIN + 1) + RAND_MIN;
		String fName = "Scat_" + randNumber + ".png";
		//File fout = new File(SHOW_FILE_PATH + "/" + fName);
		
		
        try {
    		FileOutputStream fos = new FileOutputStream(SHOW_FILE_PATH + "/" + fName);

    		XYDataset xyDataset = createXYDataset(colArr1, colArr2, dotLabel);

	    	JFreeChart chart = ChartFactory.createScatterPlot(
		            chartTitle, 
		            colName1, colName2, xyDataset);

        // force aliasing of the rendered content..
//        chart.getRenderingHints().put
//            (RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
			ChartUtilities. writeScaledChartAsPNG(fos, chart, 800, 500, 2, 2);
		} catch (Exception e) {
			msg = "Failed to create Scattergram.";
			throw new PmpException(msg);
		}
        
        fName = URL_FILE_PATH + "/" + fName;
        return fName;
    }

	/**
	 * Extract just one column of data from an input string.  Each line is separated by '@'.
	 * @param inputStr The first row is the header.  If header parameter is null, it will extract the header.
	 * @param header Header is list of column names separated by comma.
	 * @param columnName The column name that caller wants to extract.
	 * @return A string array that contains the extracted column data.
	 */
	public static String[] extractColumn(String inputStr, String [] header, String columnName) {
		// extract column data from input
		int colIdx = -1;
		inputStr = inputStr.trim();
		
		// if caller didn't pass the header in, extract the header here
		if (header == null) {
			int idx = inputStr.indexOf('@');
			String row = inputStr.substring(0, idx-1).trim();
			header = row.split(",");		// doesn't matter if I have trailing comma
		}
		
		for (int i=0; i<header.length; i++) {
			if (header[i].equals(columnName)) {
				// found the column to be extracted
				colIdx = i;
				break;
			}
		}
		
		System.out.println("extractColumn(" + columnName + ") index = " + colIdx);
		if (colIdx == -1) {
			return null;
		}
		
		int ptr = inputStr.indexOf(EOL) + 1;		// pass the header
		int strEnd = inputStr.length();
		
		// extract the column into an array
		ArrayList <String> colList = new ArrayList <String> (1024);
		String tmpStr;
		char c;
		
		while (ptr < strEnd) {
			// process one line at a time (line is separated by '@' (EOL)
			for (int i=0; i<colIdx; i++) {
				// skip "colIdx" number of comma
				while (inputStr.charAt(ptr++) != COMMA);
			}
			
			// now ptr is pointing to the beginning of the column
			tmpStr = "";
			while ((c = inputStr.charAt(ptr++)) != COMMA) {
				tmpStr += c;
			}
			colList.add(tmpStr);		// save the value
			
			// move to the end of line
			while (inputStr.charAt(ptr++)!=EOL && ptr<strEnd);
		}
		
		return colList.toArray(new String [0]);
	}	// END: extractColumn()
	

    private static XYDataset createXYDataset(String[] colArr1, String[] colArr2, String dotLabel) {
    	XYSeriesCollection dataset = new XYSeriesCollection();
    	
    	try {
	        XYSeries series1 = new XYSeries(dotLabel);
	        for (int i=0; i< colArr1.length; i++) {
	        	System.out.println(colArr1[i] + ", " + colArr2[i]);
	        	series1.add(Double.parseDouble(colArr1[i]), Double.parseDouble(colArr2[i]));
	        }
	        dataset.addSeries(series1);
    	} catch (Exception e) {e.printStackTrace();}
            
		return dataset;
	}

	private static float[][] createScattergramData(String[] colArr1, String[] colArr2) {
		// change String to float
    	int len = colArr1.length;							// colArr1 and colArr2 should be of same length
    	float [][] data = new float [2][len];
    	
    	for (int i=0; i<len; i++) {
    		data[0][i] = Float.parseFloat(colArr1[i]);
    		data[1][i] = Float.parseFloat(colArr2[i]);
    	}
		return data;
	}

	public static JFreeChart createHistChart(IntervalXYDataset dataset, String x_Legend, String chartTitle) {
        final JFreeChart chart = ChartFactory.createXYBarChart(
        	chartTitle,
            x_Legend, 
            false,
            "Frequency", 
            dataset,
            PlotOrientation.VERTICAL,
            true,
            true,
            false
        );
        XYPlot plot = (XYPlot) chart.getPlot();
        final IntervalMarker target = new IntervalMarker(400.0, 700.0);
        target.setLabel("Target Range");
        target.setLabelFont(new Font("SansSerif", Font.ITALIC, 11));
        target.setLabelAnchor(RectangleAnchor.LEFT);
        target.setLabelTextAnchor(TextAnchor.CENTER_LEFT);
        target.setPaint(new Color(222, 222, 255, 128));
        plot.addRangeMarker(target, Layer.BACKGROUND);
        return chart;    
    }

    public static IntervalXYDataset createHistogramDataset(
    		String[] dataArr, String colName, double roundPos) {
		// go thru the data and do a rounding, then count the number of same values
		double [] value = new double[dataArr.length];
		
		if (roundPos != 0.0) {
			for (int i=0; i<dataArr.length; i++) {
				value[i] = Math.round(Double.parseDouble(dataArr[i])/roundPos) * roundPos;
			}
		}
		
		int totalValue = dataArr.length;
		
		double tmpF;
		double [] num = new double [value.length];
		for (int i=0; i<num.length; i++) num[i] = 0.0;		// initialize
		
		for (int i=0; i<value.length; i++) {
			tmpF = value[i];
			if (tmpF == dNULL)
				continue;
			num[i] = 1;
			
			for (int j=i+1; j<value.length; j++) {
				if (tmpF == value[j]) {
					value[j] = dNULL;
					num[i] += 1;
					totalValue--;
				}
			}
		}
		
		// compress it by removing the "null"
		double [][] histArr = new double [totalValue][2];
		
		int idx = 0;
		for (int i=0; i<value.length; i++) {
			if (value[i] == dNULL) continue;
			
			histArr[idx][0] = value[i];
			histArr[idx][1] = num[i];
			idx++;
		}
		
		//for (int i=0; i<totalValue; i++) System.out.println(histArr[i][0] + ", " + histArr[i][1]);
		
		final XYSeries series = new XYSeries(colName + " Data");
		for (int i=0; i<totalValue; i++) {
			series.add(histArr[i][0], histArr[i][1]);
		}
		final XYSeriesCollection dataset = new XYSeriesCollection(series);
		
		return dataset;
	}
    
    
    /**
     * receive a String array of birthdate and calculate the age of each cell
     * @param birthDate
     * @return a String array contains the age
     */
    public static String [] getAge(String [] birthDateArr) {
    	String [] age = new String [birthDateArr.length];
    	long todayT = new Date().getTime();
    	long birthT;
    	
    	for (int i=0; i< birthDateArr.length; i++) {
    		try {birthT = df.parse(birthDateArr[i]).getTime();}
    		catch (ParseException e) {e.printStackTrace(); age[i] = ""; continue;}
    		
    		age[i] = String.valueOf( Math.round((todayT - birthT)/31536000000L) );
    		//System.out.println(i + ". " + age[i]);
    	}
    	return age;
    }

}
