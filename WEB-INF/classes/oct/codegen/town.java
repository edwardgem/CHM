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
//  File:   town.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//		Implementation of town class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@031704ECC	Apply for town organization.
//
/////////////////////////////////////////////////////////////////////
//
// town.java : implementation of the town class
//

package oct.codegen;
import java.util.Date;

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
import oct.pmp.exception.PmpRawGetException;
import oct.pmp.exception.PmpTypeMismatchException;
import oct.pmp.exception.PmpUnsupportedTypeException;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;
import util.StringUtil;

/**
*
* <b>General Description:</b>  town extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "town" organization.
*
* The town class provides a facility to modify data of an existing town object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.townManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class town extends PstAbstractObject

{

    //Public attributes
	public static final String TYPE_CIR_WORK		= "Work";
	public static final String TYPE_CIR_SOCIAL		= "Social";
	public static final String TYPE_CIR_ALUMNI		= "Alumni";
	public static final String TYPE_CIR_RELIGION	= "Religion";
	public static final String TYPE_CIR_FAMILY		= "Family";
	
	public static final String ATTR_OPTION			= "State";
	public static final String MAX_PROJECT 			= "MaxProject";
	public static final String MAX_USER 			= "MaxUser";
	public static final String MAX_SPACE 			= "MaxSpace";
	
	public static final String SERVICE_LEVEL 		= "Service";
	public static final String LEVEL_1				= "Basic";
	public static final String LEVEL_2				= "Team";
	public static final String LEVEL_3				= "Workgroup";
	public static final String LEVEL_4				= "Enterprise";
	public static final String DEFAULT_LEVEL		= LEVEL_1;
	
	// default limits on services
	public static final int DEFAULT_MAX_PROJ		= 5;
	public static final int DEFAULT_MAX_USER		= 10;
	public static final int DEFAULT_MAX_SPACE		= 1;		// GB
	
	public static final String PAYMT_MONTHLY		= "Monthly";
	public static final String PAYMT_YEARLY			= "Yearly";
	public static final String DEFAULT_PAYMENT_METHOD	= PAYMT_MONTHLY;
	
	private static final int MAX_COMP_LENGTH = 25;	// max company object name length


    private static townManager manager = null;
    private static projectManager pjMgr = null;
    private static userManager uMgr = null;
	
	static {
		try {
			manager = townManager.getInstance();
			pjMgr = projectManager.getInstance();
			uMgr = userManager.getInstance();
		}
		catch (PmpException e) {}
	}


    /**
     * Constructor for instantiating a new town.
     * @param member An OmsMember representing a town.
     */
    public town(OmsMember member)
    {
        super(member);
        try
        {
            manager = townManager.getInstance();
        }
        catch(PmpException pe)
        {
            //throw new PmpInternalException("Error getting townManager instance.");
        }
    }//End Constructor





    /**
     * Constructor for instantiating a new town.
     * @param user A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	town(PstUserAbstractObject user, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(user, org, memberName, password);
	}



    /**
     * Constructor for creating a town.  Used by townManager.
     * @param user A PmpUser.
     * @param org The OmsOrganization for the town.
     */
    town(PstUserAbstractObject user, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(user, org, "");
		try
		{
			manager = townManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting townManager instance.");
		}
    }//End Constructor

    /**
     * Constructor for creating a town.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the town.
     */
    town(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
         try
         {
            manager = townManager.getInstance();
         }
         catch(PmpManagerCreationException pe)
         {
             throw new PmpInternalException("Error getting townManager instance.");
         }
    }//End Constructor

    /**
     * Constructor for creating a town using a member name.
     * @param user A PmpUser.
     * @param org The OmsOrganization for the town.
     * @param townMemName The member name for the created town.
     */
    town(PstUserAbstractObject user, OmsOrganization org, String townMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(user, org, townMemName, null);
        try
        {
          manager = townManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting townManager instance.");
        }
    }//End Constructor

    /**
     * Constructor for creating a town using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the town.
     * @param companyMemberName The member name for the created town.
     */
    town(OmsSession session, OmsOrganization org, String townMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, townMemName, null);
        try
        {
           manager = townManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting townManager instance.");
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
     }//End appendAttribute

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
     * return the limit of project, user, space based on subscription
     * @param limitType
     * @return
     * @throws PmpException
     */
    public int getLimit(String limitType)
    	throws PmpException
    {
    	String option = getSubAttribute(ATTR_OPTION, limitType);
    	if (option == null) {
    		// the town doesn't have limit set, set it to default now
    		int iLimitValue = limitType.equals(MAX_USER) ? DEFAULT_MAX_USER :
    								(limitType.equals(MAX_PROJECT) ? DEFAULT_MAX_PROJ : DEFAULT_MAX_SPACE);
    		String limitValue = String.valueOf(iLimitValue);
    		setLimit(limitType, limitValue);		// it will commit
    		return iLimitValue;
    	}
    	else {
    		return Integer.parseInt(option);
    	}
    	
    }
    
    public void setLimit(String limitType, String limitValue)
    	throws PmpException
    {
    	setSubAttribute(manager, ATTR_OPTION, limitType, limitValue);
    }
    
    public boolean isReachLimit(String limitType)
    	throws PmpException
    {
    	PstGuest u = PstGuest.getInstance();
    	int [] ids = new int[0];
    	int max = getLimit(limitType);
    	if (limitType.equals(MAX_PROJECT)) {
    		ids = pjMgr.findId(u, "TownID='" + getObjectId()
    				+ "' && Option!='%" + project.PERSONAL + "%'");		// don't count personal project
    	}
    	else if (limitType.equals(MAX_USER)) {
    		ids = uMgr.findId(u, "TownID='" + getObjectId() + "'");
    	}
		return ids.length >= max;
    }
    
    /**
     *  levelS is 1, 2, 3 or 4
     */
    public static String getLevelString(String levelS)
    {
    	if (levelS == null) return null;
    	
		if (levelS.equals("1")) levelS = userinfo.LEVEL_1;
		else if (levelS.equals("2")) levelS = userinfo.LEVEL_2;
		else if (levelS.equals("3")) levelS = userinfo.LEVEL_3;
		else if (levelS.equals("4")) levelS = userinfo.LEVEL_4;
		return levelS;
    }
    
    /**
     * 
     * levelStr is userinfo.LEVEL_1, etc. which is Basic, etc.
     * @return a number (starts from 1) in String
     */
    public static String getLevelNum(String levelStr)
    {
    	if (levelStr == null) return null;
    	
    	if (levelStr.equals(userinfo.LEVEL_1)) return "1";
    	else if (levelStr.equals(userinfo.LEVEL_2)) return "2";
    	else if (levelStr.equals(userinfo.LEVEL_3)) return "3";
    	else if (levelStr.equals(userinfo.LEVEL_4)) return "4";
    	else return levelStr;
    }
    
    /**
     * Derive a company (town) object name from a user entered display name
     * The method only do a check to see if the derived name already exist,
     * but it doesn't actually create the town object.
     */
    public static String getCompanyNameFromString(String compDispName)
    	throws PmpException
    {
    	String [] sa = compDispName.split(" ");
    	String s, compName = "";
    	
    	for (int i=0; i<sa.length; i++) {
    		s = sa[i].toUpperCase();
    		if (s.endsWith(",") || s.endsWith("."))
    			s = s.substring(0, s.length()-1);		// remove token trailing . or ,
    		if (s.equals("INC"))
    			break;
    		if (compName.length() > 0) compName += "-";
    		compName += s;
    		if (compName.length() >= MAX_COMP_LENGTH) break;
    	}
    	if (compName.length() <= 0) {
    		throw new PmpException("The company name (" + compDispName + ") is invalid.");
    	}
    	if (compName.length() > MAX_COMP_LENGTH)
    		compName = compName.substring(0, MAX_COMP_LENGTH);
    	
    	// check to see if the name already exist
    	try {
    		manager.get(PstGuest.getInstance(), compName);
    		throw new PmpException("The company name (" + compDispName + ") is already used.");
    	}
    	catch (PmpException e) {}	// failed to get compName is good
    	return compName;
    }
    
    /**
     * create the company (town) object based on the user-supplied company name.
     * Optionally fill in the company information.
     */
    public static town createCompany(String compDispName, String deptName, String acctMgrIdS)
    	throws PmpException
    {
    	String compObjName = getCompanyNameFromString(compDispName);
		PstAbstractObject tObj = manager.create(PstGuest.getInstance(), compObjName, null);
		Date now = new Date();
		tObj.setAttribute("Name", compDispName);
		tObj.setAttribute("DepartmentName", deptName);
		tObj.setAttribute("AccountManager", acctMgrIdS);
		tObj.setAttribute("CreatedDate", now);
		tObj.setAttribute("StartDate", now);
		manager.commit(tObj);
		
		return (town)tObj;
    }
    
    // typeS can be @CAT (category), @PRC (process type) or @DEP (user dept)
    public String [] getTrackerOption(String typeS)
    {
    	String [] retArr = null;
    	try {
			String optionStr = getStringAttribute("Category");
			if (!StringUtil.isNullOrEmptyString(optionStr)) {
				
				String [] sa;
				String s;
				int idx1 = optionStr.indexOf(typeS);
				if (idx1 != -1) {
					idx1 += typeS.length()+1;		// skip @CAT=
					int idx2 = optionStr.indexOf("@", idx1);
					if (idx2==-1)
						idx2 = optionStr.length();
					s = optionStr.substring(idx1, idx2);
					sa = s.split(";");
					retArr = new String[sa.length];
					for (int i=0; i<sa.length; i++) {
						retArr[i] = sa[i];
					}
				}
			}
    	}
    	catch (PmpException e) {}
		return retArr;
    }


}//End class town
