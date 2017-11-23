
//
//  Copyright (c) 2004, eGuanxi, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   dl.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//		Implementation of dl class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@033004ECC	Support appending single data value to multiple data attribute.
//
/////////////////////////////////////////////////////////////////////
//
// dl.java : implementation of the dl class
//

package oct.codegen;
import java.util.ArrayList;
import java.util.List;

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
import oct.pst.PstUserAbstractObject;

/**
*
* <b>General Description:</b>  dl extends PmpAbstractObject.  This class
* encapulates the data of a member from the "dl" organization.
*
* The dl class provides a facility to modify data of an existing dl object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.dlManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class dl extends PstAbstractObject

{
	public static final String PROJECTID = "ProjectID";
	public static final String OWNER = "Owner";
	public static final String CREATEDDATE = "CreatedDate";
	public static final String LASTUPDATEDDATE = "LastUpdatedDate";
	public static final String TEAMMEMBERS = "TeamMembers";
	
	public static final String DLESCAPESTR = "DL. ";
	
    //Private attributes


    static dlManager manager;

    /**
     * Constructor for instantiating a new dl.
     * @param member An OmsMember representing a dl.
     */
    public dl(OmsMember member)
    {
        super(member);
        try
        {
            manager = dlManager.getInstance();
        }
        catch(PmpException pe)
        {
            //throw new PmpInternalException("Error getting dlManager instance.");
        }
    }//End Constructor





    /**
     * Constructor for instantiating a new dl.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	dl(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a dl.  Used by dlManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the dl.
     */
    dl(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(userObj, org, "");
		try
		{
			manager = dlManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting dlManager instance.");
		}
    }//End Constructor

    /**
     * Constructor for creating a dl.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the dl.
     */
    dl(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
         try
         {
            manager = dlManager.getInstance();
         }
         catch(PmpManagerCreationException pe)
         {
             throw new PmpInternalException("Error getting dlManager instance.");
         }
    }//End Constructor

    /**
     * Constructor for creating a dl using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the dl.
     * @param dlMemName The member name for the created dl.
     */
    dl(PstUserAbstractObject userObj, OmsOrganization org, String dlMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, dlMemName, null);
        try
        {
          manager = dlManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting dlManager instance.");
        }
    }//End Constructor

    /**
     * Constructor for creating a dl using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the dl.
     * @param companyMemberName The member name for the created dl.
     */
    dl(OmsSession session, OmsOrganization org, String dlMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, dlMemName, null);
        try
        {
           manager = dlManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting dlManager instance.");
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

    }
    
    /**
     * Fetch all the TeamMembers from project and all the members from dl. The two array
     * are stored in an object []. If an object does not contain any members it will return
     * an object array with size one with value null.
     * Object[0] = project TeamMembers // default members
     * Object[1] = dl TeamMembers // manually added members
     * @param pstuser
     * @return Two object array each also containing an object array.
     */
    public Object[] getAllTeamMembers(PstUserAbstractObject pstuser) throws PmpException {
		Object projId = getAttribute(PROJECTID)[0];
		Object [] objArr = new Object[2];
		objArr[1] = getAttribute(TEAMMEMBERS);
		// Project DL
		if (projId != null) {
			projectManager projMgr = projectManager.getInstance();
			project projObj = (project)projMgr.get(pstuser, Integer.parseInt((String)projId));
	    	objArr[0] = projObj.getAttribute(TEAMMEMBERS);
		}
		// User DL
		else {
			Object [] temp = new Object[1];
			temp[0] = null;
			objArr[0] = temp;
		}
		return objArr;
    } // End getAttribute

    /**
     * Retreives all the TeamMembers by calling getAllTeamMembers. Goes through the 
     * list and adds them into an ArrayList. Handles null cases. 
     * This method is used to concat all the TeamMembers from different distribution list. 
     * If no TeamMembers found, returns an empty ArrayList.
     * @param pstuser
     * @return All the TeamMember ids in ArrayList.
     * @throws PmpException
     */
    public List getUserIds(PstUserAbstractObject pstuser, boolean isStringType) throws PmpException {
    	List arrList = new ArrayList();
    	Object [] allTeamMem = getAllTeamMembers(pstuser);
    	
    	Object [] defaultTeamMem = (Object[])allTeamMem[0];
    	Object [] otherTeamMem = (Object[])allTeamMem[1];
    	
    	for(int i = 0; i < defaultTeamMem.length; i++) {
    		Object obj = defaultTeamMem[i];
    		if (obj != null) {
    			if(isStringType)
    				arrList.add(obj.toString());
    			else
    				arrList.add(obj);
    		}
    	}
    	for(int i =0; i < otherTeamMem.length; i++) {    
			Object obj = otherTeamMem[i];
			if(obj != null) {
				if(isStringType)
					arrList.add(obj.toString());
				else
					arrList.add(obj);
			}
    	}
    	return arrList;
    }
    
    /**
     * Removes the 
     * @param dlId
     * @return
     */
    public static int getId(String dlId) {
    	if(dlId.startsWith(DLESCAPESTR))
    		return Integer.parseInt((String)dlId.substring(DLESCAPESTR.length()));
    	else
    		return -1;
    }

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

}//End class dl
