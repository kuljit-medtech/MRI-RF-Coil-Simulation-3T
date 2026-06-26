%% =========================================================================
%  Surface_Current_Viewer.m
%  Visualises the surface current density (A/m) on the RF coil conductor.
%  FILE NEEDED: Test_3D_JS.h5
%  (rename: surface_current__f_123___AC1_.h5  ->  Test_3D_JS.h5)
%  Press F5 to run.
% =========================================================================

clear; clc; close all;

FONT_NAME = 'Times New Roman';
FONT_SIZE = 12;
FILENAME  = 'Test_3D_JS.h5';

% Force ALL default text/axes to black so nothing inherits gray
set(groot,'defaultAxesFontName',   FONT_NAME);
set(groot,'defaultAxesFontSize',   FONT_SIZE);
set(groot,'defaultAxesXColor',     'k');
set(groot,'defaultAxesYColor',     'k');
set(groot,'defaultAxesZColor',     'k');
set(groot,'defaultAxesColor',      'w');
set(groot,'defaultTextFontName',   FONT_NAME);
set(groot,'defaultTextFontSize',   FONT_SIZE);
set(groot,'defaultTextColor',      'k');

% Belt-and-suspenders: also set via set(0,...) for older MATLAB versions
set(0,'DefaultAxesFontName',  FONT_NAME);
set(0,'DefaultAxesFontSize',  FONT_SIZE);
set(0,'DefaultTextFontName',  FONT_NAME);
set(0,'DefaultTextFontSize',  FONT_SIZE);
set(0,'DefaultTextColor',     'k');

%% --- CHECK FILE ----------------------------------------------------------
if ~isfile(FILENAME)
    error(['File not found: %s\n' ...
           'Rename surface_current__f_123___AC1_.h5 to Test_3D_JS.h5\n' ...
           'and place it in: %s'], FILENAME, pwd);
end
fprintf('Reading %s ...\n', FILENAME);

%% --- READ DATA -----------------------------------------------------------
pos_raw = h5read(FILENAME, '/Position');
x_mm = double(pos_raw.x) * 1e3;
y_mm = double(pos_raw.y) * 1e3;
z_mm = double(pos_raw.z) * 1e3;

js_raw  = h5read(FILENAME, '/Surface current');
Jx_mag  = sqrt(double(js_raw.x.re).^2 + double(js_raw.x.im).^2);
Jy_mag  = sqrt(double(js_raw.y.re).^2 + double(js_raw.y.im).^2);
Jz_mag  = sqrt(double(js_raw.z.re).^2 + double(js_raw.z.im).^2);
J_mag   = sqrt(Jx_mag.^2 + Jy_mag.^2 + Jz_mag.^2);

area_elem = double(h5read(FILENAME, '/Area'));

%% --- PRINT SUMMARY -------------------------------------------------------
fprintf('\n--- Surface Current Summary ---\n');
fprintf('Mesh points    : %d\n',         length(J_mag));
fprintf('Peak |J_S|     : %.4f A/m\n',   max(J_mag));
fprintf('Mean |J_S|     : %.4f A/m\n',   mean(J_mag));
fprintf('Weighted mean  : %.4f A/m\n',   sum(J_mag.*area_elem)/sum(area_elem));
fprintf('x range        : %.2f to %.2f mm\n', min(x_mm), max(x_mm));
fprintf('z range        : %.2f to %.2f mm\n', min(z_mm), max(z_mm));
fprintf('y range        : %.4f to %.4f mm\n', min(y_mm), max(y_mm));
fprintf('--------------------------------\n\n');

%% =========================================================================
%  FIGURE 1 - 3D scatter view
% =========================================================================
fig1 = figure('Name','Surface Current - 3D View', ...
              'Color','w','Units','normalized','Position',[0.01 0.25 0.48 0.65]);
colormap(fig1, jet(256));

scatter3(x_mm, z_mm, y_mm, 20, J_mag, 'filled');
axis equal; grid on; box on;
view(15, 30);

cb = colorbar;
cb.FontName = FONT_NAME; cb.FontSize = FONT_SIZE; cb.Color = 'k';
ylabel(cb,'|J_S| (A/m)','FontName',FONT_NAME,'FontSize',FONT_SIZE,'Color','k');

xlabel('x (mm)','FontName',FONT_NAME,'FontSize',FONT_SIZE,'Color','k');
ylabel('z (mm)','FontName',FONT_NAME,'FontSize',FONT_SIZE,'Color','k');
zlabel('y (mm)','FontName',FONT_NAME,'FontSize',FONT_SIZE,'Color','k');

title({'Surface Current Density |J_S| on RF Coil Conductor'; ...
       sprintf('123 MHz  |  1W stimulated power  |  peak = %.3f A/m', max(J_mag))}, ...
      'FontName',FONT_NAME,'FontSize',FONT_SIZE,'FontWeight','bold','Color','k');

set(gca,'FontName',FONT_NAME,'FontSize',FONT_SIZE, ...
        'XColor','k','YColor','k','ZColor','k','Color','w');

%% =========================================================================
%  FIGURE 2 - Top-down XZ view
% =========================================================================
fig2 = figure('Name','Surface Current - Top View (XZ)', ...
              'Color','w','Units','normalized','Position',[0.51 0.15 0.47 0.75]);
colormap(fig2, jet(256));

% Create axes manually in lower 80% of figure - top 20% left for titles
ax2 = axes('Parent', fig2, 'Units', 'normalized', ...
           'Position', [0.13, 0.08, 0.65, 0.78]);

scatter(ax2, x_mm, z_mm, 24, J_mag, 'filled');
axis(ax2, 'equal'); axis(ax2, 'tight'); grid(ax2, 'on'); box(ax2, 'on');

cb2 = colorbar(ax2);
cb2.FontName = FONT_NAME; cb2.FontSize = FONT_SIZE; cb2.Color = 'k';
ylabel(cb2,'|J_S| (A/m)','FontName',FONT_NAME,'FontSize',FONT_SIZE,'Color','k');

xlabel(ax2,'x (mm)','FontName',FONT_NAME,'FontSize',FONT_SIZE,'Color','k');
ylabel(ax2,'z (mm)','FontName',FONT_NAME,'FontSize',FONT_SIZE,'Color','k');
set(ax2,'FontName',FONT_NAME,'FontSize',FONT_SIZE,'XColor','k','YColor','k','Color','w');

% Two-line title using sgtitle (figure-level, always above everything)
sg = sgtitle({'Surface Current Density - Top View (XZ plane)', ...
              'Red = peak current   |   Blue = minimum   |   Peaks near port/capacitor gaps'});
sg.FontName   = 'Times New Roman';
sg.FontSize   = 12;
sg.FontWeight = 'bold';
sg.Color      = 'k';%% =========================================================================
%  FIGURE 3 - Current vs circumferential angle
% =========================================================================
fig3 = figure('Name','Surface Current vs Angle', ...
              'Color','w','Units','normalized','Position',[0.10 0.0 0.80 0.30]);

theta          = atan2d(z_mm, x_mm);
[th_s, idx_s]  = sort(theta);
J_s            = J_mag(idx_s);
J_smooth       = movmean(J_s, 7);

plot(th_s, J_s,      'Color',[0.78 0.78 0.78],'LineWidth',0.9); hold on;
plot(th_s, J_smooth, 'Color',[0.05 0.30 0.75],'LineWidth',2.2);

% --- FIXED: white legend box, black border, black text, correct font -----
lgd = legend({'Raw','Smoothed (7-pt avg)'},'Location','best');
lgd.FontName  = FONT_NAME;
lgd.FontSize  = FONT_SIZE - 1;
lgd.TextColor = 'k';
lgd.Color     = 'w';          % white background  <-- KEY FIX
lgd.EdgeColor = 'k';          % visible black border
% -------------------------------------------------------------------------

xlabel('Circumferential angle (deg)','FontName',FONT_NAME,'FontSize',FONT_SIZE,'Color','k');
ylabel('|J_S| (A/m)',                'FontName',FONT_NAME,'FontSize',FONT_SIZE,'Color','k');

title({'Surface Current Distribution vs Circumferential Angle'; ...
       'Uniform current = flat line   |   Deviations = port / capacitor influence'}, ...
      'FontName',FONT_NAME,'FontSize',FONT_SIZE,'FontWeight','bold','Color','k');

grid on; box on;
xlim([-180 180]);
xticks(-180:45:180);
set(gca,'FontName',FONT_NAME,'FontSize',FONT_SIZE,'XColor','k','YColor','k','Color','w');

port_angles = [0, 90, 180, -90];
port_labels = {'Port 1 (feed+Cm)','Port 2 (Ct)','Port 3 (Ct)','Port 4 (Ct)'};
for k = 1:4
    xline(port_angles(k),'--r',port_labels{k}, ...
          'FontName',FONT_NAME,'FontSize',9, ...
          'LabelHorizontalAlignment','center', ...
          'LabelVerticalAlignment','bottom', ...
          'Color','r','LabelColor','k');
end

disp('==============================================');
disp(' Surface Current Viewer ready.');
disp(' Figure 1: 3D view of current on coil ring');
disp(' Figure 2: Top-down XZ view (ring face-on)');
disp(' Figure 3: Current vs circumferential angle');
disp('==============================================');