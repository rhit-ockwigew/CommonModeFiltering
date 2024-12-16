% This is a script written by Ethan Ockwig, last updated on 11/11/2024

function rfsb(A, B, name)
% inputs are ports of A and ports of B
% example A = [1 3], B = [2 4], name = "exampleName"
% run in Command Window -> rfsb([1 3],[2 4],"exampleName")
% This example would give you S12, S14, S32, and S34

% this is a file to measure 4 port S parameters using the copper mount VNA
% add path to the file, downloadable at https://www.minicircuits.com/softwaredownload/rfswitchcontroller.html
USB_Switch = NET.addAssembly('C:\Users\ockwigew\Downloads\mcl_RF_Switch_Controller64_dll\mcl_RF_Switch_Controller_NET45.dll');

% Also available at this link: https://www.minicircuits.com/softwaredownload/rfswitchcontroller.html
% is the GUI which allows manual control over the switchbox which is
% helpful for calibration

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
write(vna, [uint8(char("SENS:AVER:COUN 10")),nl])

write(vna, [uint8('INIT:CONT:ALL ON'), nl]);
 
write(vna, [uint8('*OPC?'), nl]);

% relay box setup
SW1=mcl_RF_Switch_Controller_NET45.USB_RF_SwitchBox;
SW1.Connect;


for i = 1:length(A)
    for j = 1:length(B)
        % Sets switch box ports
        SW1.Send_SCPI(strcat("SP6TA:STATE:",num2str(A(i))),'');
        SW1.Send_SCPI(strcat('SP6TB:STATE:',num2str(B(j))),'');

        % clears averaging and begins new measurements
        write(vna, [uint8(char("SENS:AVER:CLE")),nl])
        write(vna, [uint8('TRIG:SING'), nl]);
        write(vna, [uint8('*OPC?'), nl]);
        opc_response = VNAread(vna);

        % Saves S Parameters to a .s2p file
        write(vna, [uint8(char(strcat("MMEM:STOR:SNP ",pwd,"\",name,"S",num2str(A(i)),num2str(B(j))))),nl]);
        write(vna, [uint8('*OPC?'), nl]);
        opc_response = VNAread(vna);

        % Optional: Plot the S Parameters
        figure();
        data = sparameters(strcat(name,"S",num2str(A(i)),num2str(B(j)),".s2p"));
        rfplot(data)
    end
end

% close all relays
SW1.Send_SCPI('SP6TA:STATE:0','');
SW1.Send_SCPI('SP6TB:STATE:0','');

% return to internal trigger
write(vna, [uint8('TRIG:SOUR INT'), nl]);

end

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