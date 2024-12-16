% This is a script written by Ethan Ockwig, last updated on 11/11/2024

function rfsb2(A, B, name)
% inputs are ports of A and ports of B
% example A = [1 3], B = [2 4], name = "exampleName"
% run in Command Window -> rfsb([1 3],[2 4],"exampleName")
% This example would give you S12, S14, S32, and S34

% this is a file to measure 4 port S parameters using the agilent VNA
% add path to the file, downloadable at https://www.minicircuits.com/softwaredownload/rfswitchcontroller.html
USB_Switch = NET.addAssembly('C:\Users\ockwigew\Downloads\mcl_RF_Switch_Controller64_dll\mcl_RF_Switch_Controller_NET45.dll');

% Also available at this link: https://www.minicircuits.com/softwaredownload/rfswitchcontroller.html
% is the GUI which allows manual control over the switchbox which is
% helpful for calibration

% IP 169.254.40.176
% Connects to device
vna = visadev("TCPIP0::AGILENT-9892D87::5025::SOCKET")
% Set the buffer size
vna.InputBufferSize = 100000;
% Set the timeout value
vna.Timeout = 10;
% Set the Byte order
vna.ByteOrder = 'little-endian';
% Open the connection
fopen(vna);

% sets external trigger
fprintf(vna, 'TRIG:SOUR EXT');

% sets the VNA to store the file as an s2p with dB
fprintf(vna, 'MMEM:STOR:TRAC:FORM:SNP DB')

% sets smoothing and averaging
%fprintf(vna, 'CALC:SMO:STAT ON');
fprintf(vna, 'SENS:AVER:STAT ON');
fprintf(vna, "SENS:AVER:COUN 10")

fprintf(vna, 'INIT:CONT OFF');
 
fprintf(vna, '*OPC?');

% relay box setup
SW1=mcl_RF_Switch_Controller_NET45.USB_RF_SwitchBox;
SW1.Connect;


for i = 1:length(A)
    for j = 1:length(B)
        % Sets switch box ports
        SW1.Send_SCPI(strcat("SP6TA:STATE:",num2str(A(i))),'');
        SW1.Send_SCPI(strcat('SP6TB:STATE:',num2str(B(j))),'');

        % clears averaging and begins new measurements
        fprintf(vna, "SENS:AVER:CLE")
        fprintf(vna, 'INIT:IMM');
        fprintf(vna, '*OPC?');

        % Saves S Parameters to a .s2p file
        %fprintf(vna, strcat("DATA:SNP:PORT:SAVE'1,2 ",pwd,"\",name,"S",num2str(A(i)),num2str(B(j))));
        fprintf(vna, '*OPC?');

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
fprintf(vna, 'TRIG:SOUR INT');
fprintf(vna, 'INIT:CONT ON');
fclose(vna);

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

