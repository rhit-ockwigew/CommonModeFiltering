% This is a script written by Ethan Ockwig, last updated on 8/15/2024

% this is a file to measure 4 port S parameters using the copper mount VNA
% add path to the file, downloadable at https://www.minicircuits.com/softwaredownload/rfswitchcontroller.html
USB_Switch = NET.addAssembly('C:\Users\ockwigew\Downloads\mcl_RF_Switch_Controller64_dll\mcl_RF_Switch_Controller_NET45.dll');

% IMPORTANT!
% Before running this script,
% The socket must be turned on by going to "system" -> "misc setup" 
% -> "network remote control settings" -> "socket server (on)" in the
% VNA software

nl = 10; % this is the decimal value of a new line character ('\n')

% Connect to VNA3,1
try
    vna = tcpclient("127.0.0.1", 5025, "Timeout", 20, "ConnectTimeout", 5);
catch ME
    disp('Error establishing TCP connection.');
    disp('Check that the TCP server is on.');
    return
end

write(vna, [uint8('*IDN?'), nl]);
disp(char(VNAread(vna)));

% lets the matlab trigger the 
write(vna, [uint8('TRIG:SOUR BUS'), nl]);

% sets the VNA to store the file as an s2p with dB
write(vna, [uint8('MMEM:STOR:SNP:TYPE:S2P'), nl]);
write(vna, [uint8('MMEM:STOR:SNP:FORM:DB'), nl]);


% sets smoothing and averaging
write(vna, [uint8('CALC:SMO:ON'), nl]);
write(vna, [uint8('SENS:AVER:STAT ON'), nl]);
write(vna, [uint8('TRIG:AVER ON'), nl]);
write(vna, [uint8(char("SENS:AVER:COUN 1000")),nl])

write(vna, [uint8('INIT:CONT:ALL ON'), nl]);
 
write(vna, [uint8('*OPC?'), nl]);

% relay box setup
SW1=mcl_RF_Switch_Controller_NET45.USB_RF_SwitchBox;
SW1.Connect;

name = 'test';


%S21
SW1.Send_SCPI('SP6TA:STATE:1','');
SW1.Send_SCPI('SP6TB:STATE:2','');
write(vna, [uint8(char("SENS:AVER:CLE")),nl])
write(vna, [uint8('TRIG:SING'), nl]);
write(vna, [uint8('*OPC?'), nl]);
opc_response = VNAread(vna);



write(vna, [uint8(char("MMEM:STOR:SNP "+ pwd + "\" + name + "S21")),nl]);
write(vna, [uint8('*OPC?'), nl]);
opc_response = VNAread(vna);

%S41
SW1.Send_SCPI('SP6TB:STATE:4','');
write(vna, [uint8(char("SENS:AVER:CLE")),nl])
write(vna, [uint8('TRIG:SING'), nl]);
write(vna, [uint8('*OPC?'), nl]);
opc_response = VNAread(vna);

write(vna, [uint8(char("MMEM:STOR:SNP "+ pwd + "\" + name + "S41")),nl]);
write(vna, [uint8('*OPC?'), nl]);
opc_response = VNAread(vna);

%S23
SW1.Send_SCPI('SP6TA:STATE:3','');
SW1.Send_SCPI('SP6TB:STATE:2','');
write(vna, [uint8(char("SENS:AVER:CLE")),nl])
write(vna, [uint8('TRIG:SING'), nl]);
write(vna, [uint8('*OPC?'), nl]);
opc_response = VNAread(vna);

write(vna, [uint8(char("MMEM:STOR:SNP "+ pwd + "\" + name + "S23")),nl]);
write(vna, [uint8('*OPC?'), nl]);
opc_response = VNAread(vna);

%S43
SW1.Send_SCPI('SP6TB:STATE:4','');
write(vna, [uint8(char("SENS:AVER:CLE")),nl])
write(vna, [uint8('TRIG:SING'), nl]);
write(vna, [uint8('*OPC?'), nl]);
opc_response = VNAread(vna);

write(vna, [uint8(char("MMEM:STOR:SNP "+ pwd + "\" + name + "S43")),nl]);
write(vna, [uint8('*OPC?'), nl]);
opc_response = VNAread(vna);


% close all relays
SW1.Send_SCPI('SP6TA:STATE:0','');
SW1.Send_SCPI('SP6TB:STATE:0','');

% return to internal trigger
write(vna, [uint8('TRIG:SOUR INT'), nl]);


S12 = sparameters(name + "S21.s2p");
S14 = sparameters(name + "S41.s2p");
S32 = sparameters(name + "S23.s2p");
S34 = sparameters(name + "S43.s2p");

S12_measured = rfparam(S12,2,1);
S14_measured = rfparam(S14,2,1);
S32_measured = rfparam(S32,2,1);
S34_measured = rfparam(S34,2,1);
diff_measured21 = (S12_measured - S14_measured - S32_measured + S34_measured)/2;
comm_measured21 = (S12_measured + S14_measured + S32_measured + S34_measured)/2;

plt1.LineWidth = 2;
fspan = 20;
f = 1:(fspan-1)/(length(diff_measured21)):fspan-(fspan-1)/(length(diff_measured21));
figure(1)
plot(f,20*log10(abs(diff_measured21)));
hold on
plot(f,20*log10(abs(comm_measured21)));
legend('Diff', 'Comm')
xlim([1,20]);
ylim([-35,1])







% read from VNA through TCP connection
% blocks until data read is not empty
% reads until new line character is received
function query_response = VNAread(app_vna)
    query_response = '';
    while true
        partial_query_response = read(app_vna);
        if(isempty(partial_query_response)~=1)
            last_index = length(partial_query_response);
            query_response = strcat(query_response, partial_query_response);
            if (partial_query_response(last_index) == 10) % 10 is newline
                break;
            end
        end
    end
end

