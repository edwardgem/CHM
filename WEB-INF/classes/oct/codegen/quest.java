//
//  Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   quest.java
//  Author: FastPath CodeGen Engine
//  Date:   06.16.2006
//  Description:
//		Implementation of quest class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@033004ECC	Support appending single data value to multiple data attribute.
//
/////////////////////////////////////////////////////////////////////
//
// quest.java : implementation of the quest class
//

package oct.codegen;
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
* <b>General Description:</b>  quest extends PmpAbstractObject.  This class
* encapulates the data of a member from the "quest" organization.
*
* The quest class provides a facility to modify data of an existing quest object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.questManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class quest extends PstAbstractObject

{

	//Public
	public final static String DELIMITER		= meeting.DELIMITER;	// "::"	separate inputs within an answer of one question
	public final static String DELIMITER1		= "@@";					// separate answer of one question from another
	public final static String DELIMITER2		= "#";					// separate numeric input of an answer
	
	public static final String TYPE_EVENT		= "event";
	public static final String TYPE_QUEST		= "quest";
	
	public static final String PUBLIC			= meeting.PUBLIC;
	public static final String PRIVATE			= meeting.PRIVATE;
	
	public static final String ST_NEW			= "new";
	public static final String ST_ACTIVE		= "active";
	public static final String ST_CANCEL		= "cancel";
	public static final String ST_CLOSE			= "close";
	
	public static final String NO_SHARE			= "NoShare";
	
	public static final int MAX_QUESTIONS		= 30;			// max 30 questions
	public static final int MAX_CHOICES			= 10;			// max 10 choices or options within a question
	
    //Private attributes


    static questManager manager;

    /**
     * Constructor for instantiating a new quest.
     * @param member An OmsMember representing a quest.
     */
    public quest(OmsMember member)
    {
        super(member);
        try
        {
            manager = questManager.getInstance();
        }
        catch(PmpException pe)
        {
            //throw new PmpInternalException("Error getting questManager instance.");
        }
    }//End Constructor





    /**
     * Constructor for instantiating a new quest.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	quest(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a quest.  Used by questManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the quest.
     */
    quest(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(userObj, org, "");
		try
		{
			manager = questManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting questManager instance.");
		}
    }//End Constructor

    /**
     * Constructor for creating a quest.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the quest.
     */
    quest(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
         try
         {
            manager = questManager.getInstance();
         }
         catch(PmpManagerCreationException pe)
         {
             throw new PmpInternalException("Error getting questManager instance.");
         }
    }//End Constructor

    /**
     * Constructor for creating a quest using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the quest.
     * @param questMemName The member name for the created quest.
     */
    quest(PstUserAbstractObject userObj, OmsOrganization org, String questMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, questMemName, null);
        try
        {
          manager = questManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting questManager instance.");
        }
    }//End Constructor

    /**
     * Constructor for creating a quest using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the quest.
     * @param companyMemberName The member name for the created quest.
     */
    quest(OmsSession session, OmsOrganization org, String questMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, questMemName, null);
        try
        {
           manager = questManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting questManager instance.");
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
     * Remove an attribute value from a multi-value attribute.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to be remove from the list.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */    
    public void removeAttributeIgnoreCase(String attributeName, Object attributeValue)
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
            super.removeDataIgnoreCase(attributeName, attributeValue);
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

}//End class quest
