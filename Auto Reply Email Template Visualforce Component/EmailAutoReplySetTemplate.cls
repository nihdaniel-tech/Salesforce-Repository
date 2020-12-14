public class EmailAutoReplySetTemplate {   
    //capture the case id
    public ID caseID {get; set;}
    public List<Case> l_case = new List<Case>();
    public List<EmailMessage> emailMessageList = new List<EmailMessage>();
    public List<Master_Holiday__c> l_MasterHoliday = new List<Master_Holiday__c>();
    public String textTemplate;
    public String bodyEmail;
    
    public String getEmailTemplate() {
        system.debug('| ===== Apex Class : EmailAutoReplySetTemplate_v2 ===== |');
        l_case = [SELECT Id, CaseNumber, Type, Origin, SuppliedEmail, ContactId, Send_Auto_Reply__c, Subject_Autoreply_Template__c, Text_Autoreply_Template__c, CreatedDate FROM Case WHERE Id =: caseID AND Origin = 'Email'];
        system.debug('| Case List: '+l_case);
        
        List<String> fromEmail = new List<String>();
        for(Case cse : l_case){
            fromEmail.add(cse.SuppliedEmail);
        }
        system.debug('| From Email Address: '+fromEmail);
        
        emailMessageList = [SELECT Id, ReplyToEmailMessageId, ParentId, ToAddress, CcAddress, BccAddress, FromAddress, MessageDate, MessageDate_Temporary__c, First_Response_Date__c, Last_Response_Date__c, InComing, Subject FROM EmailMessage WHERE ParentId =: caseID ORDER BY CreatedDate DESC LIMIT 1];
        system.debug('| emailMessageList: '+emailMessageList);
        
        List<Contact> contact_list = [SELECT Id, Name, Email, MobilePhone FROM Contact WHERE Email IN :fromEmail LIMIT 1];
        system.debug('| contact_list: ' + contact_list);
        
        List<Master_Holiday__c> MHL = [SELECT Id, Name, Type__c, Category__c, Template__c, Subject__c, Body__c, Start_Date_Time__c, Start_Date_F__c, End_Date_Time__c, End_Date_F__c, Active_Date__c, Description_ID__c, Description_EN__c, Month_ID_Start_Date__c, Month_ID_End_Date__c, Month_ID_Active_Date__c FROM Master_Holiday__c ORDER BY Type__c DESC];
        system.debug('| Master Holiday List: '+MHL);
        
        for(EmailMessage em : emailMessageList){
            for(Master_Holiday__c mh : MHL){
                if(mh.Start_Date_Time__c <= em.MessageDate && mh.End_Date_Time__c >= em.MessageDate){
                    if(mh.Type__c == 'Holiday'){
                        system.debug('| *** HOLIDAY ***');
                        l_MasterHoliday.add(mh);
                        break;
                    } else if(mh.Type__c == 'Event'){
                        system.debug('| *** EVENT ***');
                        l_MasterHoliday.add(mh);
                        break;
                    }
                } else {
                    if(mh.Type__c == 'Weekday' || mh.Type__c == 'Weekend'){
                        system.debug('| *** WEEKDAY or WEEKEND ***');
                        l_MasterHoliday.add(mh);
                    }
                }
            }
        }
        system.debug('| FINAL List Master Holiday: '+l_MasterHoliday);
        
        
        //============================================
        //==		SET EMAIL TEMPLATE				==
        //============================================
        
        String bodyTemplate = '';
        List<String> result = new List<String>();
        
        for(Master_Holiday__c holiday : l_MasterHoliday){
            bodyTemplate = holiday.Body__c;
            
            result = bodyTemplate.split('\\s');
            system.debug('======result: '+ result);
            
            for(Case cs : l_case){
                if(cs.Text_Autoreply_Template__c == null && cs.Send_Auto_Reply__c == false){
                    if(result.size() > 0){
                        for(String r : result){
                            if(textTemplate == null){
                                if(r == '[CONTACT_NAME_ID]' || r.contains('[CONTACT_NAME_ID]') == true){
                                    if(cs.ContactId != null){ textTemplate = contact_list[0].Name; }
                                    else { textTemplate = 'Temanku'; }
                                } else if(r == '[CONTACT_NAME_EN]' || r.contains('[CONTACT_NAME_EN]') == true){
                                    if(cs.ContactId != null){ textTemplate = contact_list[0].Name; }
                                    else { textTemplate = 'My Friend'; }
                                } else if(r == '[DESCRIPTION_ID]' || r.contains('[DESCRIPTION_ID]')== true){ textTemplate = holiday.Description_ID__c; }
                                else if(r == '[DESCRIPTION_EN]' || r.contains('[DESCRIPTION_EN]')== true){ textTemplate = holiday.Description_EN__c; }
                                else if(r == '[START_DATE_ID]' || r.contains('[START_DATE_ID]' )== true){
                                    String dayId_startDate = String.valueOf(Date.valueOf(holiday.Start_Date_F__c).day());
                                    String monthId_startDate = holiday.Month_ID_Start_Date__c;
                                    String yearId_startDate = String.valueOf(Date.valueOf(holiday.Start_Date_F__c).year());
                                    textTemplate = dayId_startDate + ' ' + monthId_startDate + ' ' + yearId_startDate;
                                }
                                else if(r == '[START_DATE_EN]' || r.contains('[START_DATE_EN]' )== true){
                                    DateTime StartDateEN = Datetime.newInstance(holiday.Start_Date_F__c.year(), holiday.Start_Date_F__c.month(), holiday.Start_Date_F__c.day());
                                    textTemplate = StartDateEN.format('MMMM dd, YYYY');
                                }
                                else if(r == '[END_DATE_ID]' || r.contains('[END_DATE_ID]' )== true){
                                    String dayId_endDate = String.valueOf(Date.valueOf(holiday.End_Date_F__c).day());
                                    String monthId_endDate = holiday.Month_ID_End_Date__c;
                                    String yearId_endDate = String.valueOf(Date.valueOf(holiday.End_Date_F__c).year());
                                    textTemplate = dayId_endDate + ' ' + monthId_endDate + ' ' + yearId_endDate;
                                }
                                else if(r == '[END_DATE_EN]' || r.contains('[END_DATE_EN]' )== true){
                                    DateTime EndDateEN = Datetime.newInstance(holiday.End_Date_F__c.year(), holiday.End_Date_F__c.month(), holiday.End_Date_F__c.day());
                                    textTemplate = EndDateEN.format('MMMM dd, YYYY');
                                }
                                else if(r == '[ACTIVE_DATE_ID]' || r.contains('[ACTIVE_DATE_ID]') == true){
                                    String dayId_activeDate = String.valueOf(holiday.Active_Date__c.day());
                                    String monthId_activeDate = holiday.Month_ID_Active_Date__c ;
                                    String yearId_activeDate = String.valueOf(holiday.Active_Date__c.year());
                                    textTemplate = dayId_activeDate + ' ' + monthId_activeDate + ' ' + yearId_activeDate;
                                }
                                else if(r == '[ACTIVE_DATE_EN]' || r.contains('[ACTIVE_DATE_EN]') == true){
                                    DateTime ActiveDateEN = Datetime.newInstance(holiday.Active_Date__c.year(), holiday.Active_Date__c.month(), holiday.Active_Date__c.day());
                                    textTemplate = ActiveDateEN.format('MMMM dd, YYYY');
                                } else {
                                    textTemplate = r;
                                }
                            } else {
                                if(r == '[CONTACT_NAME_ID]' || r.contains('[CONTACT_NAME_ID]') == true){
                                    if(cs.ContactId != null){ textTemplate = textTemplate+ ' ' +contact_list[0].Name; }
                                    else { textTemplate = textTemplate+ ' ' +'Temanku'; }
                                } else if(r == '[CONTACT_NAME_EN]' || r.contains('[CONTACT_NAME_EN]') == true){
                                    if(cs.ContactId != null){ textTemplate = textTemplate+ ' ' +contact_list[0].Name; }
                                    else { textTemplate = textTemplate+ ' ' +'My Friend'; }
                                } else if(r == '[DESCRIPTION_ID]' || r.contains('[DESCRIPTION_ID]')== true){
                                    textTemplate = textTemplate+' ' +holiday.Description_ID__c;
                                }
                                else if(r == '[DESCRIPTION_EN]' || r.contains('[DESCRIPTION_EN]')== true){
                                    textTemplate = textTemplate+' ' +holiday.Description_EN__c;
                                }
                                else if(r == '[START_DATE_ID]' || r.contains('[START_DATE_ID]' )== true){
                                    String dayId_startDate = String.valueOf(Date.valueOf(holiday.Start_Date_F__c).day());
                                    String monthId_startDate = holiday.Month_ID_Start_Date__c;
                                    String yearId_startDate = String.valueOf(Date.valueOf(holiday.Start_Date_F__c).year());
                                    textTemplate = textTemplate+' ' +dayId_startDate + ' ' + monthId_startDate + ' ' + yearId_startDate;
                                }
                                else if(r == '[START_DATE_EN]' || r.contains('[START_DATE_EN]' )== true){
                                    DateTime StartDateEN = Datetime.newInstance(holiday.Start_Date_F__c.year(), holiday.Start_Date_F__c.month(), holiday.Start_Date_F__c.day());
                                    textTemplate = textTemplate+' ' +StartDateEN.format('MMMM dd, YYYY');
                                }
                                else if(r == '[END_DATE_ID]' || r.contains('[END_DATE_ID]' )== true){
                                    String dayId_endDate = String.valueOf(Date.valueOf(holiday.End_Date_F__c).day());
                                    String monthId_endDate = holiday.Month_ID_End_Date__c;
                                    String yearId_endDate = String.valueOf(Date.valueOf(holiday.End_Date_F__c).year());
                                    textTemplate = textTemplate+' ' +dayId_endDate + ' ' + monthId_endDate + ' ' + yearId_endDate;
                                }
                                else if(r == '[END_DATE_EN]' || r.contains('[END_DATE_EN]' )== true){
                                    DateTime EndDateEN = Datetime.newInstance(holiday.End_Date_F__c.year(), holiday.End_Date_F__c.month(), holiday.End_Date_F__c.day());
                                    textTemplate = textTemplate+' ' +EndDateEN.format('MMMM dd, YYYY');
                                }
                                else if(r == '[ACTIVE_DATE_ID]' || r.contains('[ACTIVE_DATE_ID]') == true){
                                    String dayId_activeDate = String.valueOf(holiday.Active_Date__c.day());
                                    String monthId_activeDate = holiday.Month_ID_Active_Date__c ;
                                    String yearId_activeDate = String.valueOf(holiday.Active_Date__c.year());
                                    textTemplate = textTemplate+' ' +dayId_activeDate + ' ' + monthId_activeDate + ' ' + yearId_activeDate;
                                }
                                else if(r == '[ACTIVE_DATE_EN]' || r.contains('[ACTIVE_DATE_EN]') == true){
                                    DateTime ActiveDateEN = Datetime.newInstance(holiday.Active_Date__c.year(), holiday.Active_Date__c.month(), holiday.Active_Date__c.day());
                                    textTemplate = textTemplate+' ' +ActiveDateEN.format('MMMM dd, YYYY');
                                } else{
                                    textTemplate = textTemplate+ ' ' +r;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        bodyEmail = textTemplate;
        system.debug('| Body Email: '+bodyEmail);
        return bodyEmail;
    }
}