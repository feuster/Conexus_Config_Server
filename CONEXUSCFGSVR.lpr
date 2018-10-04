program CONEXUSCFGSVR;

{$mode objfpc}{$H+}
{$MACRO on}

{____________________________________________________________
|  _______________________________________________________  |
| |                                                       | |
| |            Config server for CONEXUS script           | |
| | (c) 2018 Alexander Feuster (alexander.feuster@web.de) | |
| |             http://www.github.com/feuster             | |
| |_______________________________________________________| |
|___________________________________________________________}

//Server code based on official Freepascal example:
//http://wiki.freepascal.org/Networking#Webserver_example

//define program basics
{$DEFINE PROGVERSION:='1.0'}
//{$DEFINE PROG_DEBUG}
{___________________________________________________________}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp,
  { you can add units after this }
  strutils, blcksock, sockets, Synautil
  ;

type

  { TApp }

  TApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    procedure HelpHint; virtual;
  end;

const
  //program title
  STR_Title:    String = ' __________________________________________________ '+#13#10+
                         '|  ______________________________________________  |'+#13#10+
                         '| |                                              | |'+#13#10+
                         '| |**********************************************| |'+#13#10+
                         '| |    Configuration Web Frontend for Conexus    | |'+#13#10+
                         '| |          (c) 2018 Alexander Feuster          | |'+#13#10+
                         '| |        http://www.github.com/feuster         | |'+#13#10+
                         '| |______________________________________________| |'+#13#10+
                         '|__________________________________________________|'+#13#10;

  //program version
  STR_Version:    String = PROGVERSION;

  //CPU architecture
  STR_CPU:      String = {$I %FPCTARGETCPU%};

  //Build info
  STR_Build:    String = {$I %FPCTARGETOS%}+' '+{$I %FPCTARGETCPU%}+' '+{$I %DATE%}+' '+{$I %TIME%};
  {$WARNINGS OFF}
  STR_User:     String = {$I %USER%};
  {$WARNINGS ON}
  STR_Date:     String = {$I %DATE%};

  //Message Strings
  STR_Info:         String = 'Info:    ';
  STR_Error:        String = 'Error:   ';
  {$IFDEF PROG_DEBUG}
  STR_Debug:        String = 'Debug:   ';
  {$ENDIF}

var
  SCRIPTPATH:       String;
  SCRIPT:           TStringList;
  STR_Title_Banner: String;

{ TApp }


procedure AttendConnection(ASocket: TTCPBlockSocket);
var
  Timeout:          Integer;
  Buffer:           String;
  Uri:              String;
  Method:           String;
  Protocol:         String;
  BaseUri:          String;
  OutputDataString: String;
  URL:              String;
  PIN:              String;
  CODE:             String;
  CODEList:         String;
  BANNER:           String;
  Index:            Integer;

begin
  Timeout:=120000;

  //read request line
  Buffer:=ASocket.RecvString(Timeout);
  Method:=fetch(Buffer, ' ');
  Uri:=fetch(Buffer, ' ');
  Protocol:=fetch(Buffer, ' ');
  BaseUri:=ASocket.GetLocalSinIP;
  WriteLn(STR_Info,'request URI "'+Uri+'" ('+Method+'|'+Protocol+')');

  //check if URI ist a GET Uri
  if LeftStr(Uri,2)='/?' then
    begin
      //read GET variables
      Uri:=UpperCase(Uri);
      CODE:=StringReplace(fetch(Uri, '&'),'/?CODE=', '', [rfReplaceAll,rfIgnoreCase]);
      URL:=StringReplace(fetch(Uri, '&'),'URL=', '', [rfReplaceAll,rfIgnoreCase]);
      PIN:=StringReplace(fetch(Uri, ''),'PIN=', '', [rfReplaceAll,rfIgnoreCase]);

      //read BASH script and update values
      SCRIPT.Clear;
      SCRIPT.LoadFromFile(SCRIPTPATH);
      //write remote code
      for Index:=0 to SCRIPT.Count-1 do
        begin
          if LeftStr(UpperCase(SCRIPT.Strings[Index]),5)='CODE=' then
            begin
              SCRIPT.Strings[Index]:='CODE='+CODE;
              break;
            end;
        end;
      //write device URL
      for Index:=0 to SCRIPT.Count-1 do
        begin
          if LeftStr(UpperCase(SCRIPT.Strings[Index]),4)='URL=' then
            begin
              SCRIPT.Strings[Index]:='URL='+URL;
              break;
            end;
        end;
      //write device PIN
      for Index:=0 to SCRIPT.Count-1 do
        begin
          if LeftStr(UpperCase(SCRIPT.Strings[Index]),4)='PIN=' then
            begin
              SCRIPT.Strings[Index]:='PIN='+PIN;
              break;
            end;
        end;

      //save updated bash script and create info banner
      try
      SCRIPT.SaveToFile(SCRIPTPATH);
      BANNER:='<div id="banner"><fieldset style="background-color:#009900;"><h2><center>New configuration saved!</h2></center></fieldset></div><script>setTimeout(function(){ document.getElementById(''banner'').innerHTML = ''''; window.location = window.location.pathname; }, 3000); </script>';
      WriteLn(STR_Info,'"'+SCRIPTPATH+'" updated');
      except
      BANNER:='<div id="banner"><fieldset style="background-color:#990000;"><h2><center>New configuration could not be saved!</h2></center></fieldset></div><script>setTimeout(function(){ document.getElementById(''banner'').innerHTML = ''''; window.location = window.location.pathname; }, 3000); </script>';
      WriteLn(STR_Error,'"'+SCRIPTPATH+'" could not be updated');
      end;

      //Reset Uri to load standard page afterwards with actualized BASH script
      Uri:='/';
    end;

  //set default values
  if Uri='/' then
    begin
      //read BASH script
      SCRIPT.Clear;
      SCRIPT.LoadFromFile(SCRIPTPATH);

      //Default values
      URL:='Please enter the device IP or domain name';
      PIN:='1234';
      CODE:='ALL';
      //read remote code
      for Index:=0 to SCRIPT.Count-1 do
        begin
          if LeftStr(UpperCase(SCRIPT.Strings[Index]),5)='CODE=' then
            begin
              CODE:=UpperCase(MidStr(SCRIPT.Strings[Index],6,Length(SCRIPT.Strings[Index])-5));
              break;
            end;
        end;
      //read device URL
      for Index:=0 to SCRIPT.Count-1 do
        begin
          if LeftStr(UpperCase(SCRIPT.Strings[Index]),4)='URL=' then
            begin
              URL:=MidStr(SCRIPT.Strings[Index],5,Length(SCRIPT.Strings[Index])-4);
              break;
            end;
        end;
      //read device PIN
      for Index:=0 to SCRIPT.Count-1 do
        begin
          if LeftStr(UpperCase(SCRIPT.Strings[Index]),4)='PIN=' then
            begin
              PIN:=MidStr(SCRIPT.Strings[Index],5,Length(SCRIPT.Strings[Index])-4);
              break;
            end;
        end;
    end;

  //create HTML output part for remote selection
  if CODE='ALL' then
    begin
      CODEList:='<input type="radio" id="ALL" name="CODE" value="ALL" checked><label for="ALL"> ALL</label><input type="radio" id="SAT1" name="CODE" value="SAT1"><label for="SAT1"> SAT1</label><input type="radio" id="SAT2" name="CODE" value="SAT2"><label for="SAT2"> SAT2</label><input type="radio" id="VCR1" name="CODE" value="VCR1"><label for="VCR1"> VCR1</label><input type="radio" id="VCR2" name="CODE" value="VCR2"><label for="VCR2"> VCR2</label><input type="radio" id="TV1" name="CODE" value="TV1"><label for="TV1"> TV1</label><input type="radio" id="TV2" name="CODE" value="TV2"><label for="TV2"> TV2</label>';
    end
  else if CODE='SAT1' then
    begin
      CODEList:='<input type="radio" id="ALL" name="CODE" value="ALL"><label for="ALL"> ALL</label><input type="radio" id="SAT1" name="CODE" value="SAT1" checked><label for="SAT1"> SAT1</label><input type="radio" id="SAT2" name="CODE" value="SAT2"><label for="SAT2"> SAT2</label><input type="radio" id="VCR1" name="CODE" value="VCR1"><label for="VCR1"> VCR1</label><input type="radio" id="VCR2" name="CODE" value="VCR2"><label for="VCR2"> VCR2</label><input type="radio" id="TV1" name="CODE" value="TV1"><label for="TV1"> TV1</label><input type="radio" id="TV2" name="CODE" value="TV2"><label for="TV2"> TV2</label>';
    end
  else if CODE='SAT2' then
    begin
      CODEList:='<input type="radio" id="ALL" name="CODE" value="ALL"><label for="ALL"> ALL</label><input type="radio" id="SAT1" name="CODE" value="SAT1"><label for="SAT1"> SAT1</label><input type="radio" id="SAT2" name="CODE" value="SAT2" checked><label for="SAT2"> SAT2</label><input type="radio" id="VCR1" name="CODE" value="VCR1"><label for="VCR1"> VCR1</label><input type="radio" id="VCR2" name="CODE" value="VCR2"><label for="VCR2"> VCR2</label><input type="radio" id="TV1" name="CODE" value="TV1"><label for="TV1"> TV1</label><input type="radio" id="TV2" name="CODE" value="TV2"><label for="TV2"> TV2</label>';
    end
  else if CODE='VCR1' then
    begin
      CODEList:='<input type="radio" id="ALL" name="CODE" value="ALL"><label for="ALL"> ALL</label><input type="radio" id="SAT1" name="CODE" value="SAT1"><label for="SAT1"> SAT1</label><input type="radio" id="SAT2" name="CODE" value="SAT2"><label for="SAT2"> SAT2</label><input type="radio" id="VCR1" name="CODE" value="VCR1" checked><label for="VCR1"> VCR1</label><input type="radio" id="VCR2" name="CODE" value="VCR2"><label for="VCR2"> VCR2</label><input type="radio" id="TV1" name="CODE" value="TV1"><label for="TV1"> TV1</label><input type="radio" id="TV2" name="CODE" value="TV2"><label for="TV2"> TV2</label>';
    end
  else if CODE='VCR2' then
    begin
      CODEList:='<input type="radio" id="ALL" name="CODE" value="ALL"><label for="ALL"> ALL</label><input type="radio" id="SAT1" name="CODE" value="SAT1"><label for="SAT1"> SAT1</label><input type="radio" id="SAT2" name="CODE" value="SAT2"><label for="SAT2"> SAT2</label><input type="radio" id="VCR1" name="CODE" value="VCR1"><label for="VCR1"> VCR1</label><input type="radio" id="VCR2" name="CODE" value="VCR2" checked><label for="VCR2"> VCR2</label><input type="radio" id="TV1" name="CODE" value="TV1"><label for="TV1"> TV1</label><input type="radio" id="TV2" name="CODE" value="TV2"><label for="TV2"> TV2</label>';
    end
  else if CODE='TV1' then
    begin
      CODEList:='<input type="radio" id="ALL" name="CODE" value="ALL"><label for="ALL"> ALL</label><input type="radio" id="SAT1" name="CODE" value="SAT1"><label for="SAT1"> SAT1</label><input type="radio" id="SAT2" name="CODE" value="SAT2"><label for="SAT2"> SAT2</label><input type="radio" id="VCR1" name="CODE" value="VCR1"><label for="VCR1"> VCR1</label><input type="radio" id="VCR2" name="CODE" value="VCR2"><label for="VCR2"> VCR2</label><input type="radio" id="TV1" name="CODE" value="TV1" checked><label for="TV1"> TV1</label><input type="radio" id="TV2" name="CODE" value="TV2"><label for="TV2"> TV2</label>';
    end
  else if CODE='TV2' then
    begin
      CODEList:='<input type="radio" id="ALL" name="CODE" value="ALL"><label for="ALL"> ALL</label><input type="radio" id="SAT1" name="CODE" value="SAT1"><label for="SAT1"> SAT1</label><input type="radio" id="SAT2" name="CODE" value="SAT2"><label for="SAT2"> SAT2</label><input type="radio" id="VCR1" name="CODE" value="VCR1"><label for="VCR1"> VCR1</label><input type="radio" id="VCR2" name="CODE" value="VCR2"><label for="VCR2"> VCR2</label><input type="radio" id="TV1" name="CODE" value="TV1"><label for="TV1"> TV1</label><input type="radio" id="TV2" name="CODE" value="TV2" checked><label for="TV2"> TV2</label>';
    end
  else
    begin
      CODEList:='<input type="radio" id="ALL" name="CODE" value="ALL" checked><label for="ALL"> ALL</label><input type="radio" id="SAT1" name="CODE" value="SAT1"><label for="SAT1"> SAT1</label><input type="radio" id="SAT2" name="CODE" value="SAT2"><label for="SAT2"> SAT2</label><input type="radio" id="VCR1" name="CODE" value="VCR1"><label for="VCR1"> VCR1</label><input type="radio" id="VCR2" name="CODE" value="VCR2"><label for="VCR2"> VCR2</label><input type="radio" id="TV1" name="CODE" value="TV1"><label for="TV1"> TV1</label><input type="radio" id="TV2" name="CODE" value="TV2"><label for="TV2"> TV2</label>';
    end;
  CODEList:='<h2>Remote code</h2>'+CODEList;

  //Create full HTML page and write the document to the output stream
  if Uri='/' then
    begin
      OutputDataString :=
        '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"'
        + ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' + CRLF
        + '<html><head>' + CRLF
        + '<style>body {font-family: Verdana, Arial, Helvetica, sans-serif} fieldset {padding-top:10px; border:1px solid #000035;	border-radius:8px; box-shadow:0 0 10px #000035;}</style></head>' + CRLF
        + '<center><h1><u><b>CONEXUS Configuration ('+BaseUri+')</b></u></h1><h2>Please set up the preferred IR remote code and the URL/PIN to your network device</h2></center>' + CRLF
        + '<br><br><br>' + CRLF
        + '<form><center>' + CRLF
        + '<fieldset>' + CODEList + '</fieldset><br>' + CRLF
        + '<fieldset><label for="URL"><h2>Device URL</h2></label><input type="text" size="64" maxlength="128" id="URL" name="URL" value="'+URL+'"></fieldset><br>' + CRLF
        + '<fieldset><label for="PIN"><h2>Device PIN</h2></label><input type="text" size="4" maxlength="4" id="PIN" name="PIN" value="'+PIN+'"></fieldset><br>' + CRLF;
      //use update banner or update button
      if Banner<>'' then
        begin
          OutputDataString:=OutputDataString + Banner + CRLF
        end
      else
        begin
          OutputDataString:=OutputDataString
            + '<fieldset><h2>Update Configuration</h2><button type="submit">UPDATE NOW</button></fieldset></center>'+ CRLF
        end;
      OutputDataString:=OutputDataString
        + '</form>' + CRLF
        + '</html>' + CRLF;

      {$IFDEF PROG_DEBUG}
      WriteLn(STR_Debug,'HTML output:');
      WriteLn('--------------------------------------------------------------------------------');
      WriteLn(OutputDataString);
      WriteLn('--------------------------------------------------------------------------------');
      {$ENDIF}

      // Write the headers back to the client
      ASocket.SendString('HTTP/1.0 200' + CRLF);
      ASocket.SendString('Content-type: Text/Html' + CRLF);
      ASocket.SendString('Content-length: ' + IntTostr(Length(OutputDataString)) + CRLF);
      ASocket.SendString('Connection: close' + CRLF);
      ASocket.SendString('Date: ' + Rfc822DateTime(now) + CRLF);
      ASocket.SendString('Server: Conexus Config Server V' + PROGVERSION + CRLF);
      ASocket.SendString('' + CRLF);

      {$IFDEF PROG_DEBUG}
      if ASocket.LastError <> 0 then
        WriteLn(STR_Debug,'Socket error '+intToStr(ASocket.LastError)+': '+ASocket.LastErrorDesc);
      {$ENDIF}

      // Write the document back to the browser
      ASocket.SendString(OutputDataString);
    end
  else
    ASocket.SendString('HTTP/1.0 404' + CRLF);
end;

procedure TApp.DoRun;
var
  ErrorMsg: String;
  ListenerSocket, ConnectionSocket: TTCPBlockSocket;
  Port:     String;

begin
  //add CPU architecture info to title
  if STR_CPU='x86_64' then
    {$IFDEF PROG_DEBUG}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','   Conexus Config Server V'+STR_Version+' Debug (64Bit)   ',[])
    {$ELSE}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','      Conexus Config Server V'+STR_Version+' (64Bit)      ',[])
    {$ENDIF}
  else if STR_CPU='i386' then
    {$IFDEF PROG_DEBUG}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','   Conexus Config Server V'+STR_Version+' Debug (32Bit)   ',[])
    {$ELSE}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','      Conexus Config Server V'+STR_Version+' (32Bit)      ',[])
    {$ENDIF}
  else
    {$IFDEF PROG_DEBUG}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','      Conexus Config Server V'+STR_Version+' Debug        ',[]);
    {$ELSE}
    STR_Title_Banner:=StringReplace(STR_Title,'**********************************************','          Conexus Config Server V'+STR_Version+'          ',[]);
    {$ENDIF}

  // quick check parameters
  ErrorMsg:=CheckOptions('hlnbs:p:', 'help license nobanner build script: port:');
  if ErrorMsg<>'' then begin
    //write title banner
    WriteLn(STR_Title_Banner);
    WriteLn(STR_Error+ErrorMsg);
    HelpHint;
    Terminate;
    Exit;
  end;

  //show banner if not surpressed
  if (HasOption('n', 'nobanner')=false) or (HasOption('s', 'showbanner')=true) then
    WriteLn(STR_Title_Banner);

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  //show build info
  if HasOption('b', 'build') then
    begin
      if STR_User<>'' then
        {$IFDEF PROG_DEBUG}
        WriteLn(STR_Info,'Build "V'+STR_Version+' '+STR_Build+'" (DEBUG) compiled by "'+STR_User+'"')
        {$ELSE}
        WriteLn(STR_Info,'Build "V'+STR_Version+' '+STR_Build+'" compiled by "'+STR_User+'"')
        {$ENDIF}
      else
        {$IFDEF PROG_DEBUG}
        WriteLn(STR_Info,'Build "V'+STR_Version+' (DEBUG) '+STR_Build+'"');
        {$ELSE}
        WriteLn(STR_Info,'Build "V'+STR_Version+' '+STR_Build+'"');
        {$ENDIF}
      Terminate;
      Exit;
    end;

  //show license info
  if HasOption('l', 'license') then
    begin
      //show Conexus license
      WriteLn('Conexus Config Server V'+STR_Version+' (c) '+STR_Date[1..4]+' Alexander Feuster (alexander.feuster@web.de)'+#13#10+
              'http://www.github.com/feuster'+#13#10+
              'This program is provided "as-is" without any warranties for any data loss,'+#13#10+
              'device defects etc. Use at own risk!'+#13#10+
              'Free for personal use. Commercial use is prohibited without permission.'+#13#10);
      Terminate;
      Exit;
    end;

  //check for BASH script
  if HasOption('s', 'script') then
    begin
      SCRIPTPATH:=(GetOptionValue('s', 'script'));
      WriteLn(STR_Info,'using script "'+SCRIPTPATH+'" for configuration');
    end
  else
    begin
      WriteLn(STR_Error+'No path to BASH scriptfile specified');
      HelpHint;
      Terminate;
      Exit;
    end;

  //check if BASH script does exist
  if FileExists(SCRIPTPATH)=false then
    begin
      WriteLn(STR_Error+'BASH scriptfile does not exist');
      HelpHint;
      Terminate;
      Exit;
    end;

  //check for server port
  if HasOption('p', 'port') then
    begin
      Port:=(GetOptionValue('p', 'port'));
    end
  else
    begin
      WriteLn(STR_Info+'No server port has been specified. Using default port 80.');
      Port:='80';
    end;
  {$IFDEF PROG_DEBUG}WriteLn(STR_Debug,'using server port "'+Port+'"');{$ENDIF}

  //StringList for later loaded script content
  SCRIPT:=TStringList.Create;

  //Server sockets
  ListenerSocket:=TTCPBlockSocket.Create;
  ConnectionSocket:=TTCPBlockSocket.Create;
  ListenerSocket.CreateSocket;
  ListenerSocket.setLinger(true,10);
  ListenerSocket.bind('0.0.0.0',Port);
  ListenerSocket.listen;

  //Server loop
  repeat
    if ListenerSocket.canread(1000) then
      begin
        ConnectionSocket.Socket:=ListenerSocket.accept;
        {$IFDEF PROG_DEBUG}WriteLn(STR_Debug,'Attending Connection. Error code (0=Success): ', ConnectionSocket.lasterror);{$ENDIF}
        AttendConnection(ConnectionSocket);
        ConnectionSocket.CloseSocket;
      end;
  until false;

  //Cleanup
  if ListenerSocket<>NIL then ListenerSocket.Free;
  if ConnectionSocket<>NIL then ConnectionSocket.Free;
  if SCRIPT<>NIL then SCRIPT.Free;

  //Stop program loop
  Terminate;
end;

constructor TApp.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TApp.Destroy;
begin
  inherited Destroy;
end;

procedure TApp.WriteHelp;
begin
  { add your help code here }
  WriteLn('General usage:          ', ExtractFileName(ExeName), ' --script=[path to BASH script]');
  WriteLn('                        or');
  WriteLn('                        ', ExtractFileName(ExeName), ' -s [path to BASH script]');
  WriteLn('');
  WriteLn('All program functions:');
  WriteLn('Help:              ', ExtractFileName(ExeName), ' -h (--help)');
  WriteLn('                   Show this help text.'+#13#10);
  WriteLn('Build info:        ', ExtractFileName(ExeName), ' -b (--build)');
  WriteLn('                   Show the program build info.'+#13#10);
  WriteLn('Banner:            ', ExtractFileName(ExeName), ' -n (--nobanner)');
  WriteLn('                   Hide the banner.'+#13#10);
  WriteLn('                   ', ExtractFileName(ExeName), ' -s (--showbanner)');
  WriteLn('                   Just show the banner (overrides -n --nobanner).'+#13#10);
  WriteLn('License info:      ', ExtractFileName(ExeName), ' -l (--license)');
  WriteLn('                   Show license info.'+#13#10);
  WriteLn('Script path:       ', ExtractFileName(ExeName), ' -s (--script)');
  WriteLn('                   Path to CONEXUS BASH script which has configuration options stored.'+#13#10);
  WriteLn('Server port:       ', ExtractFileName(ExeName), ' -p (--port)');
  WriteLn('                   Server port for accessing the configuration page (Default: 80)'+#13#10);
end;

procedure TApp.HelpHint;
//show a hint for the help function
begin
  WriteLn(STR_Info+'Try "', ExtractFileName(ExeName), ' -h" or "', ExtractFileName(ExeName), ' --help" for a detailed help.');
  WriteLn(STR_Info+'Try "', ExtractFileName(ExeName), ' -l" or "', ExtractFileName(ExeName), ' --license" for the license.');
end;

var
  Application: TApp;
begin
  Application:=TApp.Create(nil);
  Application.Title:='CONEXUS Config Server';
  Application.Run;
  Application.Free;
end.

