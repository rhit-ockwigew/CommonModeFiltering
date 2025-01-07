% This is a script written by Ethan Ockwig, last updated on 12/19/2024

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

writeline(vna, "CALC:PAR:DEL:ALL");
writeline(vna,"CALC1:PAR:DEF:EXT 'CH1_S11', 'S11'");
writeline(vna, "CALC:PAR:SEL 'CH1_S11'");
writeline(vna, "DISP:WIND:TRAC1:FEED 'CH1_S11'");
writeline(vna,"CALC1:PAR:DEF:EXT 'CH1_S12', 'S12'");
writeline(vna, "CALC:PAR:SEL 'CH1_S12'");
writeline(vna, "DISP:WIND:TRAC2:FEED 'CH1_S12'");
writeline(vna,"CALC1:PAR:DEF:EXT 'CH1_S21', 'S21'");
writeline(vna, "CALC:PAR:SEL 'CH1_S21'");
writeline(vna, "DISP:WIND:TRAC3:FEED 'CH1_S21'");
writeline(vna,"CALC1:PAR:DEF:EXT 'CH1_S22', 'S22'");
writeline(vna, "CALC:PAR:SEL 'CH1_S22'");
writeline(vna, "DISP:WIND:TRAC4:FEED 'CH1_S22'");

% writeline(vna, "MMEM:LOAD:CORR

% sets external trigger
writeline(vna, 'TRIG:SOUR EXT');

%sets to little endian
writeline(vna, 'FORM:BORD SWAP');

% Set data type to real 64 bit binary block
writeline(vna, 'FORM REAL,64');

% sets smoothing and averaging
%writeline(vna, "CALC:PAR:SEL 'CH1_S11_1'");
writeline(vna, 'CALC:SMO ON');
writeline(vna, 'SENS:AVER:STAT ON');
writeline(vna, "SENS:AVER:COUN 10")

writeline(vna, 'INIT:CONT OFF');
 
writeline(vna, '*OPC?');

% relay box setup
SW1=mcl_RF_Switch_Controller_NET45.USB_RF_SwitchBox;
SW1.Connect;
readline(vna);

for i = 1:length(A)
    for j = 1:length(B)
        % Sets switch box ports
        SW1.Send_SCPI(strcat("SP6TA:STATE:",num2str(A(i))),'');
        SW1.Send_SCPI(strcat('SP6TB:STATE:',num2str(B(j))),'');

        % clears averaging and begins new measurements
        writeline(vna, "SENS:AVER:CLE");
        writeline(vna, 'INIT:IMM');
        writeline(vna, '*OPC?');

        % Saves the trace data to an s2p file
        writeline(vna, 'CALC:DATA:SNP? 2');
        data = readbinblock(vna, 'double');
        data_r=reshape(data, [(length(data)/9),9]);
        data_r=data_r';
        freqs=data_r(1,:);
        s11 = 10.^(data_r(2,:)/20).*exp(data_r(3,:).*sqrt(-1).*3.14/180);
        s12 = 10.^(data_r(4,:)/20).*exp(data_r(5,:).*sqrt(-1).*3.14/180);
        s21 = 10.^(data_r(6,:)/20).*exp(data_r(7,:).*sqrt(-1).*3.14/180);
        s22 = 10.^(data_r(8,:)/20).*exp(data_r(9,:).*sqrt(-1).*3.14/180);
        s = zeros(2,2,length(s11));
        s(1,1,:) = s11;
        s(1,2,:) = s12;
        s(2,1,:) = s21;
        s(2,2,:) = s22;
        rfwrite(s,freqs,strcat(pwd,"\",name,"S",num2str(A(i)),num2str(B(j)),".s2p"));
        
        % Optional: Plot the S Parameters
        figure();
        data = sparameters(strcat(name,"S",num2str(A(i)),num2str(B(j)),".s2p"));
        rfplot(data)
    end
end

% close all relays
SW1.Send_SCPI('SP6TA:STATE:0','');
SW1.Send_SCPI('SP6TB:STATE:0','');

% return to preset settings
writeline(vna, 'SYST:PRES');
fclose(vna);

end

