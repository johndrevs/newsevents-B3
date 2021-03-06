<cfsetting enablecfoutputonly="yes"> 
<cfif isnumeric(url.siteid)>
<cfset n=url.siteid>
<cfelse>
<cfabort>
</cfif>
<CFQUERY NAME="getsiteinfo" DATASOURCE="#application.datasource_select#">
SELECT      site_name, uri, description, maxrows
FROM         CUNVMCS.sites 
where siteid =#n#
</CFQUERY>
Next we will connect to our database and get the tutorials (or whatever you want to syndicate):
<cfparam name="month" default="#DatePart('m', Now())#">
<cfparam name="year" default="#DatePart('yyyy', Now())#">
<cfparam name="week" default="#DatePart('ww', Now())#">
<cfif isDefined("url.day") IS 0>
	<cfset url.day = "#DatePart('d', Now())#">
<cfelseif url.day gt 27 and url.month is 2>
<cfset url.day = 27>
<cfelseif url.day is 31>
<cfset url.day = 30></cfif>
<cfset currentdate = CreateDate(year, month, day)>
<cfquery name="qgetevents" datasource="#application.datasource_select#">
SELECT 
  EVE.EVENTID, EVE.USERID, 
  EVE.CREATED, EVE.PUBDATE, EVE.STARTDATE, 
  EVE.ENDDATE, EVE.PULLDATE, EVE.SHORTDESC, 
  EVE.LONGDESC,  EVE.lastmod, EVE.INFO_CLOB, EVE.EVENTS_LINK,  EVE.EVENTS_LINK_OVERRIDE,
  EVE.LOCATIONID, EVE.SPECIFICLOCATION, EVE.SPONSOR, 
  EVE.CONTACT,EVE.CONTACTINFO, EVE.CREATOR, EVE.RSVP_PUBLIC, 
  EVE.RSVP, EVE.EVENTS_COST, EVE.ISPUBLIC, REGISTRATION_LINK,INVITED
FROM 

  CUNVMCS.EVENTS_TBL EVE, CUNVMCS.events_ref REF
		where	0=0 and EVE.isactive=1 and REF.eventid=EVE.eventid and REF.siteid=#n# and REF.events_ref_level =2 AND (to_char(startdate, 'yyyy-mm-dd') >= '#dateformat(currentdate,"yyyy-mm-dd")#')
	and to_char(pubdate, 'yyyy-mm-dd') <= to_char(SYSDATE, 'yyyy-mm-dd') and to_char(pulldate, 'yyyy-mm-dd') >= to_char(SYSDATE, 'yyyy-mm-dd') order by startdate</cfquery>

<cfsavecontent variable="theXML">

<cfoutput><?xml version="1.0" encoding="ISO-8859-1" ?>
<?xml-stylesheet href="style.xsl" type="text/xsl" media="screen"?>
  <rss version="2.0">
    <channel>
       <title>Loyola University Chicago #getsiteinfo.site_name# Calendar</title>
       <link>#application.url#/public/calendar.cfm?siteid=#url.siteid#</link>
       <description>Events from the Loyola University Chicago Calendar</description>
       <language>en-us</language>
       <copyright>Copyright 2006 Loyola University Chicago</copyright>
       <docs>http://backend.userland.com/rss/</docs>
	  
       <lastBuildDate>#dateformat(now(), "ddd, dd mmm yyyy")# #timeformat(now(), "HH:mm:ss")# EST</lastBuildDate>
</cfoutput>

<cfloop from="1" to="#qgetevents.RecordCount#" index="ctr">
<cfquery name="getlocation" datasource="#application.datasource_select#" maxrows=1>
select location_name,location_link
from cunvmcs.locations
where locationid=#qgetevents.locationid[ctr]#</cfquery>
    <!--- Here let's clean up and ensure that all values are XML Compliant --->
    <cfscript>
       title = replace(qgetevents.shortdesc[ctr], "<", "&lt;", "ALL");
	    title = replace(title, "&", "&amp;", "ALL");
       description = replace(qgetevents.INFO_CLOB[ctr], "<", "&lt;", "ALL");
       description = replace(description, "&", "&amp;", "ALL");
	   
	   description = replace(description, "'", "&apos;", "ALL");
       description = replace(description, '-', "'", "ALL");
       date = dateformat(qgetevents.pubdate[ctr], "ddd, dd mmm yyyy");
       time = timeformat(qgetevents.pubdate[ctr], "HH:mm:ss") & " EST";
	

   </cfscript>
   <cfparam name="attributes.MSText" default="">
<cfparam name="attributes.ReplaceQuotes" default="true">
<cfparam name="attributes.QuotesType" default="text">
<cftry>	
	<cfset variables.MSRubbish = description>
	<cfcatch type="Any">
		<p><b>CleanMSText</b></p>
		<p>Error: You must specify the name of the variable which contains the MS text.</p>
		<p><i>&lt;cf_cleanvariables.MSRubbish mstext="MyString"&gt;</i></p>
		<cfabort>
	</cfcatch>
</cftry>

<cfscript>
	variables.FoundFlag = 1;
	
	// these ones are easy
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, '<o:p>', '', 'all');
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, '</o:p>', '', 'all');
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, ' class=MsoNormalTable', '', 'all');
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, ' class="MsoNormalTable"', '', 'all');
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, ' class=MsoNormal', '', 'all');
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, ' class="MsoNormal"', '', 'all');
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, ' lang=EN-US', '', 'all');
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, ' lang="EN-US"', '', 'all');
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, ' lang=EN-GB', '', 'all');
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, ' lang="EN-GB"', '', 'all');
	// stops it ditching the bold markups when throwing away smart tags
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, '<strong>', '<b>', 'all');
	variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, '</strong>', '</b>', 'all');	
	// mso xml tags
	variables.MSRubbish = REReplaceNoCase(variables.MSRubbish, '<?xml[^>]*microsoft[^>]*>', '', 'ALL');
	// this one's interesting... mso "smart tags", 
	// xml jubblies which seem to attach themselves to place names etc.
	variables.MSRubbish = REReplaceNoCase(variables.MSRubbish, '<st[^>]*>', '', 'ALL');
	variables.MSRubbish = REReplaceNoCase(variables.MSRubbish, '</st[^>]*>', '', 'ALL');
	
	if (attributes.ReplaceQuotes EQ true OR NOT IsBoolean(attributes.ReplaceQuotes)) {
		// replace MS smart quotes
		if (attributes.QuotesType EQ 'code') {
			// single quotes
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(145), '&lsquo;', 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(146), '&rsquo;', 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(24), '&lsquo;', 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(25), '&rsquo;', 'all');
			// double quotes
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(147), '&ldquo;', 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(148), '&rdquo;', 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(28), '&ldquo;', 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(29), '&rdquo;', 'all');
		} else {
			// single quotes
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(145), Chr(39), 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(146), Chr(39), 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(24), Chr(39), 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(25), Chr(39), 'all');
			// double quotes
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(147), Chr(34), 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(148), Chr(34), 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(28), Chr(34), 'all');
			variables.MSRubbish = Replace(variables.MSRubbish, Chr(29), Chr(34), 'all');
		}
		variables.MSRubbish = Replace(variables.MSRubbish, Chr(19), "-", 'all');		
	}
	
	// next ones are style="blah blah blah", class=MSo...
	While (variables.FoundFlag EQ 1) {
		if (FindNoCase(' class=mso', variables.MSRubbish)) {
			// these are mso default stylesheets... useless in your html output
			variables.StartIndex = FindNoCase(' class=mso', variables.MSRubbish);
			variables.NextSpace = Find(' ', variables.MSRubbish, variables.StartIndex + 10);
			variables.NextClose = Find('>', variables.MSRubbish, variables.StartIndex + 10);
			if (variables.NextSpace LT variables.NextClose) {
				variables.EndIndex = variables.NextSpace;
			} else {
				variables.EndIndex = variables.NextClose;
			}			
			variables.RemoveString = Mid(variables.MSRubbish, variables.StartIndex, variables.EndIndex-variables.StartIndex);
			variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, variables.RemoveString, '', 'all');
		} else if (FindNoCase(' style="', variables.MSRubbish)) {
			// more stylesheets...
			variables.StartIndex = FindNoCase(' style="', variables.MSRubbish);
			variables.EndIndex = Find('"', variables.MSRubbish, variables.StartIndex + 9) + 1;
			variables.RemoveString = Mid(variables.MSRubbish, variables.StartIndex, variables.EndIndex-variables.StartIndex);			
			variables.MSRubbish = ReplaceNoCase(variables.MSRubbish, variables.RemoveString, '', 'all');
		} else {
			// none of the above... probably ought to stop unless you
			// feel really nasty and want to knacker somebody's server
			variables.FoundFlag = 0;
		}
	}
	
	// Remove all empty span tags that have no nested html tags between them
	variables.MSRubbish = REReplaceNoCase(variables.MSRubbish,"<span>([^<]*)</span>","\1","ALL");
	// Now we have to remove all other empty span tag pairs, without affecting any
	// non-empty nested span tags... It's not as simple as you'd first think

	// variables.spanArray[x][1] = remove flag (1=remove, 0=ignore)
	// variables.spanArray[x][2] = index of opening tag
	// variables.spanArray[x][3] = index of closing tag
	variables.spanArray = ArrayNew(2);
	variables.spanIndex = 1;
	
	while (FindNoCase("<span", variables.MSRubbish, variables.spanIndex)
			OR FindNoCase("</span>", variables.MSRubbish, variables.spanIndex)) {
		
		variables.nextOpen = FindNoCase("<span", variables.MSRubbish, variables.spanIndex);
		variables.nextClosed = FindNoCase("</span>", variables.MSRubbish, variables.spanIndex);
		
		if (variables.nextOpen NEQ 0 AND variables.nextOpen LT variables.nextClosed) {
			// next span tag is an opening tag
			variables.arrIndex = ArrayLen(variables.spanArray) + 1;
			if (Mid(variables.MSRubbish, variables.nextOpen, 6) EQ "<span>") {
				// empty start tag, flag it for removal
				variables.spanArray[variables.arrIndex][1] = 1;
				variables.spanArray[variables.arrIndex][2] = variables.nextOpen;
				variables.spanArray[variables.arrIndex][3] = 0;
			} else {
				// non-empty start tag... flag as ignore
				variables.spanArray[variables.arrIndex][1] = 0;
				variables.spanArray[variables.arrIndex][2] = variables.nextOpen;	
				variables.spanArray[variables.arrIndex][3] = 0;			
			}
			variables.spanIndex = variables.nextOpen + 6;
		} else if (variables.nextClosed NEQ 0) {
			// next span tag is a closing tag. Find the last available zero in 
			// the third position of dimention 2 of the array
			for (i=ArrayLen(variables.spanArray); i GTE 1; i=i-1) {
				if (variables.spanArray[i][3] EQ 0) {
					variables.spanArray[i][3] = variables.NextClosed;
					break;
				}
			}			
			variables.spanIndex = variables.nextClosed + 7;
		} else {
			// nextOpen and nextClosed are both zero... this shouldn't happen
			break;
		}		
	}
	
	// now we go through the array backwards and remove the offending tags
	for (i=ArrayLen(variables.spanArray); i GTE 1; i=i-1) {
		if (variables.spanArray[i][1] EQ 1) {
			// remove end tag </span>
			variables.MSRubbish = RemoveChars(variables.MSRubbish, variables.spanArray[i][3], 7);
			// now remove start tag <span>
			variables.MSRubbish = RemoveChars(variables.MSRubbish, variables.spanArray[i][2], 6);
		}
	}
	
	// Send it back,

</cfscript>
   <!--- this is the area your users will really want, these are the actual RSS items.. where you have your news or your content itself ---> 
   <cfoutput>
   <item>
         <title>#title#</title> 
         <description><![CDATA[#startdate#<cfif (isDefined("qgetevents.allday") AND qgetevents.allday EQ 1) or timeformat(qgetevents.startdate[ctr],"h:mm:tt") EQ '1:00:am'>
		#dateformat(qgetevents.startdate[ctr],"dddd mmmm d, yyyy")# <cfif qgetevents.enddate[ctr] is not '' and datecompare(qgetevents.startdate[ctr],qgetevents.enddate[ctr],"d") NEQ 0>to #dateformat(qgetevents.enddate[ctr],"dddd mmmm d, yyyy")#</cfif>
	<cfelseif qgetevents.enddate[ctr] IS ''>		
		#dateformat(qgetevents.startdate[ctr],"dddd mmmm d, yyyy")#  #timeformat(qgetevents.startdate[ctr],"h:mm TT")#	
	<cfelseif datecompare(qgetevents.startdate[ctr],qgetevents.enddate[ctr],"d") NEQ 0>
		#dateformat(qgetevents.startdate[ctr],"dddd mmmm d, yyyy")# at #timeformat(qgetevents.startdate[ctr],"h:mm TT")#
		 to
		 #dateformat(qgetevents.enddate[ctr],"dddd mmmm d, yyyy")# at #timeformat(qgetevents.enddate[ctr],"h:mm TT")#	
	<cfelseif datecompare(qgetevents.startdate[ctr],qgetevents.enddate[ctr],"m") EQ 0  and parameterexists(form.enddateno) neq 1>
		#dateformat(qgetevents.startdate[ctr],"dddd mmmm d, yyyy")# from #timeformat(qgetevents.startdate[ctr],"h:mm TT")# - #timeformat(qgetevents.enddate[ctr],"h:mm tt")#
	<cfelse>
	</cfif> | <cfset getlocation.location_name=replace(getlocation.location_name, "&", "&amp;", "ALL")>#getlocation.location_name#  #qgetevents.specificlocation[ctr]# | #MSRubbish# ]]></description>
         <link>#application.url#/public/calendar_detail.cfm?eventid=#qgetevents.eventid[ctr]#</link>
		  <guid isPermaLink="true">#application.url#/public/calendar_detail.cfm?eventid=#qgetevents.eventid[ctr]#</guid>

         <author>calendar@luc.edu (University Calendar)</author>
         <pubDate>#date# #time#</pubDate>
   </item>
   </cfoutput>
</cfloop>
<cfoutput>
</channel>
</rss>
</cfoutput>
</cfsavecontent>


<cfcontent type="text/xml">
<cfoutput>#theXml#</cfoutput>
