
//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   userinfo.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//		Implementation of userinfo class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//
/////////////////////////////////////////////////////////////////////
//
// userinfo.java : implementation of the userinfo class
//

package oct.codegen;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.pmp.exception.PmpCommitObjectException;
import oct.pmp.exception.PmpDeleteObjectException;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpInvalidAttributeException;
import oct.pmp.exception.PmpManagerCreationException;
import oct.pmp.exception.PmpObjectCreationException;
import oct.pmp.exception.PmpObjectException;
import oct.pmp.exception.PmpObjectNotFoundException;
import oct.pmp.exception.PmpRawGetException;
import oct.pmp.exception.PmpTypeMismatchException;
import oct.pmp.exception.PmpUnsupportedTypeException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

/**
*
* <b>General Description:</b>  userinfo extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "userinfo" organization.
*
* The userinfo class provides a facility to modify data of an existing userinfo object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.userinfoManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class userinfo extends PstAbstractObject

{
	// Public attributes
	public static final String PREF_BLOG_CHECK		= "BlogCheck";
	public static final String PREF_ACTION_FIL		= "ActionFilter";
	public static final String PREF_PROJECT_ID		= "ProjectID";		// only for director

	// timezone: to get to the corresponding index, use the userinfo TimeZone attr value +7
	public static final String [] TIME_ZONE			= {
		"GMT-7 Los Angeles, San Francisco (Pacific DST)",	// DST (March)
		//"GMT-7 Arizona",
		"GMT-6 Denver",
		"GMT-5 Chicago",
		"GMT-4 New York",
		"GMT-3 Brasilia, Rio de Janeiro",
		"",
		"",
		"GMT Greenwich Mean Time",
		"GMT+1 London",
		"GMT+2 Berlin, Paris",
		"",
		"GMT+4 Moscow, St. Petersburg",
		"",
		"",
		"GMT+7 Bangkok, Saigon",
		"GMT+8 Hong Kong, Beijing, Singapore, Perth",
		"GMT+9 Toyko, Seoul",
		"GMT+10 Brisbane, Sydney",
		"",
		"GMT+12 Fiji, Wellington, Auckland, Kamchatka"
	};
	public static final int	TOTAL_TIMEZONE = TIME_ZONE.length;
	private static final String PACIFIC_DST = "Pacific DST";
	private static final String PST_ZONE_STR = "GMT-8 Los Angeles, San Francisco (Pacific PST)";
	public static final int SERVER_TIME_ZONE = -7;		// DST: March

	/**
	 * ECC: approved
	 */
	public static boolean isPST()	// winter US
	{
		return isPST(new Date());
	    //return (tz.getDisplayName().toLowerCase().equals("pacific standard time"))?true:false;
	}

	/**
	 * ECC: approved
	 */
	public static boolean isPST(Date dt)
	{
	     java.util.TimeZone tz = Calendar.getInstance().getTimeZone();
	     return !tz.inDaylightTime(dt);
	}

	/**
	 * ECC: approved
	 */
	public static String getZoneString(int idx)
	{
		if (idx < 0) idx = 0;
		 String str = TIME_ZONE[idx];
		 if (isPST()) {
			 if (str.contains("-7"))
				 str = PST_ZONE_STR;
			 else if (str.contains("-4"))
				 str = str.replace("-4", "-5");
			 else if (str.contains("-5"))
				 str = str.replace("-5", "-6");
			 else if (str.contains("-6"))
				 str = str.replace("-6", "-7");
		 }
		 return str;
	}
	
	/**
	 * ECC: approved
	 */
	public String getZoneString()
	{
		int iTimeZone = 0;
		try {iTimeZone = ((Integer)getAttribute("TimeZone")[0]).intValue();}
		catch (PmpException e) {}	// ignore
		return getZoneString(iTimeZone+7);		// +7 because GMT is on [7] in my TIME_ZONE array
	}
	
	public String getZoneShortString()
	{
		String zoneStr = getZoneString();
		return zoneStr.substring(0, zoneStr.indexOf(' '));
	}
	
	/**
	 * ECC: approved
	 */
	public static String getServerTimeZoneID()
	{
		if (isPST(new Date())) return "GMT-08";	// PST
		else return "GMT-07";					// DST
	}

	/**
	 * ECC: approved
	 */
	public static int getServerTimeZone(Date dt)
	{
		return (isPST(dt) ? SERVER_TIME_ZONE-1 : SERVER_TIME_ZONE);
	}

	/**
	 * ECC: approved
	 */
	public static int getServerTimeZone()
	{
		// winter goes back one hour: -7 to -8
		return getServerTimeZone(new Date());
	}

	public static long getServerUTCdiff() {return getServerUTCdiff(new Date());}
	public static long getServerUTCdiff(Date dt) {return getServerTimeZone(dt) * 3600000;}

	public static Date getLocalTime(Date dt)
	{
		if (dt == null) return null;
		long t = dt.getTime() + getServerUTCdiff(dt);
		return new Date(t);
	}
	
	/**
	 * ECC: approved
	 */
	public TimeZone getTimeZone()
	{
		String tzID;
		int iTimeZone = getTimeZoneIdx();
		if (iTimeZone==0) {
			tzID = getServerTimeZoneID();
		}
		else {
			// GMT+09 or GMT-11
			tzID = "GMT" + ((iTimeZone>0)?"+":"-") + ((Math.abs(iTimeZone)>9)?"":"0") + Math.abs(iTimeZone);
		}
		return TimeZone.getTimeZone(tzID);
	}
	
	/**
	 * ECC: approved
	 */
	public int getTimeZoneIdx()
	{
		int iTimeZone = 0;
		try {iTimeZone = ((Integer)getAttribute("TimeZone")[0]).intValue();}
		catch (PmpException e) {}	// ignore
		if (iTimeZone>=-7 && iTimeZone<=-4 && isPST()) iTimeZone--;		// getServerTimeZone() will return -8
		return iTimeZone;
	}
	
	/**
	 * ECC: approved
	 */
	public static boolean isServerTimeZone(TimeZone tz)
	{
		return tz.getID().contains(getServerTimeZoneID());	// getID() has minutes like GMT-08:00
	}
	
	
	/**
	 * ECC: approved
	 */
	public int getTimeZoneDiff()
	{
		int iTimeZone = getTimeZoneIdx();
		int iServerZone = getServerTimeZone();
		return iTimeZone - iServerZone;
	}

	public static class PrmTimeZone
	{
		int _valGMT;
		String _zoneStr;

		public PrmTimeZone(int tz)
		{
			int idx = tz - SERVER_TIME_ZONE;
			if (idx < 0) idx = 0;
			_zoneStr = TIME_ZONE[idx];
			if (isPST() && _zoneStr.contains(PACIFIC_DST))
			{
				tz--;		// winter time: back one hour from -7 to -8
				_zoneStr = PST_ZONE_STR;
			}
			_valGMT = tz;
		}
		public int getVal() {return _valGMT;}
		public String getZoneString() {return _zoneStr;}
		public String getZoneShortString() {return _zoneStr.substring(0, _zoneStr.indexOf(' '));}
		public long getZoneUTCdiff() {return _valGMT * 3600000;}
	}
	
	/**
	 * setTimeZone
	 * @throws PmpInternalException 
	 * @throws PmpObjectNotFoundException 
	 */
	public static void setTimeZone(PstUserAbstractObject u, SimpleDateFormat df)
		throws PmpObjectNotFoundException, PmpInternalException
	{
		userinfo myUI = (userinfo) manager.get(u, String.valueOf(u.getObjectId()));
		TimeZone myTimeZone = myUI.getTimeZone();
		if (!userinfo.isServerTimeZone(myTimeZone)) {
			df.setTimeZone(myTimeZone);
		}
	}
	
	
	////////////////////////////
	// locale
	public static final String loc_enUs		= "en_US";
	public static final String loc_enUs_s	= "English - US";
	public static final String loc_zhCN		= "zh_CN";
	public static final String loc_zhCN_s	= "Chinese - Simplified";
	public static final String [] LOC_ARRAY		= {loc_enUs, loc_zhCN};
	public static final String [] LOC_STR_ARRAY	= {loc_enUs_s, loc_zhCN_s};
	
	public static String DEFAULT_LOCALE	= loc_enUs;
	
	/**
	 * getLocale()
	 */
	public String getLocale()
	{
		String locale = "";
		try {locale = getStringAttribute("Location");}
		catch (PmpException e) {return null;}	// problem
		return locale==null?"":locale;			// return "" if not set
	}

	
	////////////////////////////
	// service level
	public static final String LEVEL_1		= town.LEVEL_1;
	public static final String LEVEL_2		= town.LEVEL_2;
	public static final String LEVEL_3		= town.LEVEL_3;
	public static final String LEVEL_4		= town.LEVEL_4;

	// payment method
	public static final String PAYMT_MONTHLY		= town.PAYMT_MONTHLY;
	public static final String PAYMT_YEARLY			= town.PAYMT_YEARLY;

	public static final int DEFAULT_CR_SPACE		= 200;		// ep_home, post_adduser, post_account
	public static final int MAX_BACKUP_HOST			= 10;		// ep_home

    //Private attributes


    static userinfoManager manager;
    
    static {
    	try {
    		manager = userinfoManager.getInstance();
    	}
    	catch (PmpException e) {}
    }

    /**
     * Constructor for instantiating a new userinfo.
     * @param member An OmsMember representing a userinfo.
     */
    public userinfo(OmsMember member)
    {
        super(member);
    }





    /**
     * Constructor for instantiating a new userinfo.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	userinfo(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a userinfo.  Used by userinfoManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the userinfo.
     */
    userinfo(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(userObj, org, "");
		try
		{
			manager = userinfoManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting userinfoManager instance.");
		}
    }//End Constructor

    /**
     * Constructor for creating a userinfo.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the userinfo.
     */
    userinfo(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
         try
         {
            manager = userinfoManager.getInstance();
         }
         catch(PmpManagerCreationException pe)
         {
             throw new PmpInternalException("Error getting userinfoManager instance.");
         }
    }//End Constructor

    /**
     * Constructor for creating a userinfo using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the userinfo.
     * @param userinfoMemName The member name for the created userinfo.
     */
    userinfo(PstUserAbstractObject userObj, OmsOrganization org, String userinfoMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, userinfoMemName, null);
        try
        {
          manager = userinfoManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting userinfoManager instance.");
        }
    }//End Constructor

    /**
     * Constructor for creating a userinfo using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the userinfo.
     * @param companyMemberName The member name for the created userinfo.
     */
    userinfo(OmsSession session, OmsOrganization org, String userinfoMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, userinfoMemName, null);
        try
        {
           manager = userinfoManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting userinfoManager instance.");
        }
    }//End Constructor


    /**
     * Currentyly Not Implemented.
     * Determine whether attribute is settable.
     * @param attributeName Name of attribute.
     */
    private boolean isSetAuthorized(String attributeName)
    {
        return true;

    }//End isSetAuthorized

     /**
      * Set attribute value.
      * @param attributeId The attribute id.
      * @param attributeValue The single value to set the attribute to.
      * @exception PmpInvalidAttributeException The attribute is invalid.
      * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
      * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
      * @exception PmpInteralException An internal error occurred.
      */
     public void setAttribute(int attributeId, Object attributeValue)
         throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
     {
         String attributeName = manager.getAttributeName(attributeId);
         setAttribute(attributeName, attributeValue, false);
     }//End setAttribute

     /**
      * Set attribute of multiple values.  Does not support setting raw datatype with multiple values.
      * @param attributeId The attribute id.
      * @param attributeValues The array of values to set the attribute to.
      * @exception PmpInvalidAttributeException The attribute is invalid.
      * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
      * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
      * @exception PmpInteralException An internal error occurred.
      */
     public void setAttribute(int attributeId, Object [] attributeValues)
         throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
     {
         String attributeName = manager.getAttributeName(attributeId);
         setAttribute(attributeName, attributeValues);
     }//End setAttribute

     /**
      * Append attribute value.
      * @param attributeId The attribute id.
      * @param attributeValue The single value to set the attribute to.
      * @exception PmpInvalidAttributeException The attribute is invalid.
      * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
      * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
      * @exception PmpInteralException An internal error occurred.
      */
     public void appendAttribute(int attributeId, Object attributeValue)
         throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
     {
         String attributeName = manager.getAttributeName(attributeId);
         setAttribute(attributeName, attributeValue, true);
     }//End setAttribute

     /**
      * Append attribute value.
      * @param attributeName The attribute name.
      * @param attributeValue The single value to set the attribute to.
      * @exception PmpInvalidAttributeException The attribute is invalid.
      * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
      * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
      * @exception PmpInteralException An internal error occurred.
      */
     public void appendAttribute(String attributeName, Object attributeValue)
         throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
     {
 		setAttribute(attributeName, attributeValue, true);
 	}

     /**
      * Set attribute value.
      * @param attributeName The attribute name.
      * @param attributeValue The single value to set the attribute to.
      * @exception PmpInvalidAttributeException The attribute is invalid.
      * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
      * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
      * @exception PmpInteralException An internal error occurred.
      */
     public void setAttribute(String attributeName, Object attributeValue)
         throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
     {
 		setAttribute(attributeName, attributeValue, false);
 	}


     /**
      * Set attribute value.
      * @param attributeName The attribute name.
      * @param attributeValue The single value to set the attribute to.
      * @param bAppend True if the attribute value is to append to the current value list
      * @exception PmpInvalidAttributeException The attribute is invalid.
      * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
      * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
      * @exception PmpInteralException An internal error occurred.
      */
     protected void setAttribute(String attributeName, Object attributeValue, boolean bAppend)
         throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
     {
         if(! manager.isValueValid(attributeName, attributeValue))
         {
             throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
         }

         if(isSetAuthorized(attributeName) == false)
         {
             throw new PmpInvalidAttributeException("Not authorized to set.");
         }

         if(manager.getAttributeType(attributeName) == RAW)
         {
             if(attributeValue instanceof byte[] || attributeValue==null)
             {
                 super.setRawData(attributeName, (byte [])attributeValue);
             }
             else
             {
                 throw new PmpTypeMismatchException("Data is not of RAW type.");
             }
         }
         else
         {
             super.setData(attributeName, attributeValue, bAppend);	// support appending data
         }

     }//End setAttribute


     /**
      * Set attribute of multiple values.  Does not support setting raw datatype with multiple values.
      * @param attributeName The attribute name.
      * @param attributeValues The array of values to set the attribute to.
      * @exception PmpInvalidAttributeException The attribute is invalid.
      * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
      * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
      * @exception PmpInteralException An internal error occurred.
      */
     public void setAttribute(String attributeName, Object [] attributeValues)
         throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
     {
         if(! manager.isValueValid(attributeName, attributeValues))
         {
             throw new PmpTypeMismatchException("Attribute values has an incorrect type.");
         }
         else if(manager.getAttributeType(attributeName)== RAW)
         {
             //Delete raw data value if null
             if(attributeValues == null)
             {
                 super.setRawData(attributeName,null);
             }
             else
             {
                 throw new PmpUnsupportedTypeException("Raw data with multiple values is not supported.");
             }
         }

         if(isSetAuthorized(attributeName) == false)
         {
             throw new PmpInvalidAttributeException("Not authorized to set.");
         }

         super.setData(attributeName, attributeValues);

    }//End setAttribute

    /**
     * Remove an attribute value from a multi-value attribute.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to be remove from the list.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void removeAttribute(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValue))
        {
            throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
        }

        if(manager.getAttributeType(attributeName) == RAW)
        {
            throw new PmpUnsupportedTypeException("This API does not support RAW datatype.");
        }
        else
        {
            super.removeData(attributeName, attributeValue);
        }

    }//End removeAttribute

    /**
     * Get the attribute value.
     * @param attributeId The attribute id.
     * @exception PmpInvalidAttributeException The attribute does not exist.
     * @exception PmpRawGetException An error occurred obtaining the raw data.
     * @exception PmpInteralException An internal error occurred.
     * @return A non-empty array of Object values for that attribute.
     */
    public Object [] getAttribute(int attributeId)
        throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException
    {
        String attributeName = manager.getAttributeName(attributeId);
        return getAttribute(attributeName);
    }//End getAttribute

    /**
     * Get the attribute value.
     * @param attributeName The attribute name.
     * @exception PmpInvalidAttributeException The attribute does not exist.
     * @exception PmpRawGetException An error occurred obtaining the raw data.
     * @exception PmpInteralException An internal error occurred.
     * @return A non-empty array of Object values for that attribute.
     */
    public Object [] getAttribute(String attributeName)
        throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException
    {
        if(manager.getAttributeType(attributeName) == RAW)
        {
            byte [] rawResult = super.getRawData(attributeName);
            Object [] finalResult = new Object[1];
            finalResult[0] = rawResult;
            return finalResult;
        }

        if(manager.hasMultipleValues(attributeName))
        {
            return super.getMultipleData(attributeName, manager.getAttributeType(attributeName));
        }
        else
        {
            Object [] finalResult = new Object[1];
            finalResult[0] = super.getSingleData(attributeName, manager.getAttributeType(attributeName));
            return finalResult;
        }

    }//End getAttribute

    protected void delete()
        throws PmpDeleteObjectException
    {
        super.delete();
    }//End delete

    protected void save()
        throws PmpCommitObjectException
    {
        super.save();
    }//End save

    protected boolean refresh()
    {
        return super.refresh();
    }//End refresh

    /**
     * Return the preference attribute that match the key
     * e.g. Archive:1348999258015   <-- timestamp
     * @param key e.g. Archive
     * @return
     * @throws PmpException
     */
	public String getPreference(String key)
		throws PmpException
	{
		String pref;
		if (key != null) key += ":";
		Object [] prefObj = this.getAttribute("Preference");
		for (int j=0; j<prefObj.length; j++) {
			pref = (String)prefObj[j];
			if ((pref != null) && pref.startsWith(key)) {
				return pref;
			}
		}
		return null;
	}

}//End class userinfo
