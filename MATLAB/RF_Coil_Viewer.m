%% =========================================================================
%  RF_Coil_Viewer.m  -  Interactive B1+  B1-  SAR10g  slice viewer
%  Files needed (same folder):
%    RF_Coil_Viewer.m  |  Dataread3.m
%    Test_3D_B1p.h5    |  Test_3D_B1m.h5  |  Test_3D_SAR.h5
%  Run: press F5
%
%  CHANGES IN THIS VERSION:
%    - Colormap changed to "jet" (full rainbow: blue -> cyan -> green ->
%      yellow -> red), matching the standard CST-style legend.
%    - All text (titles, axis labels, tick numbers, colorbar numbers,
%      sliders, instructions) now uses Times New Roman, 12pt.
%    - Axis tick numbers (the -50/0/50 mm scale numbers) are now set to
%      white so they are visible against the dark figure background.
% =========================================================================

clear; clc; close all;

%% --- GLOBAL FONT SETTINGS (Times New Roman, 12pt, applied everywhere) ----
FONT_NAME = 'Times New Roman';
FONT_SIZE = 12;
set(groot, 'defaultAxesFontName',  FONT_NAME);
set(groot, 'defaultAxesFontSize',  FONT_SIZE);
set(groot, 'defaultTextFontName',  FONT_NAME);
set(groot, 'defaultTextFontSize',  FONT_SIZE);
set(groot, 'defaultUicontrolFontName', FONT_NAME);
set(groot, 'defaultUicontrolFontSize', FONT_SIZE);

%% --- LOAD DATA -----------------------------------------------------------
disp('Loading B1+ ...');
D_B1p = Dataread3('Test', 3, 'B1p');

disp('Loading B1- ...');
D_B1m = Dataread3('Test', 3, 'B1m');

disp('Loading SAR ...');
D_SAR  = Dataread3('Test', 3, 'SAR');

disp('All files loaded!');

%% --- EXTRACT ARRAYS ------------------------------------------------------
B1p  = double(D_B1p.Field{1});
B1m  = double(D_B1m.Field{1});
SAR  = double(D_SAR.Field{1});

x_mm = double(D_B1p.x{1});
y_mm = double(D_B1p.y{1});
z_mm = double(D_B1p.z{1});

Nx = length(x_mm);
Ny = length(y_mm);
Nz = length(z_mm);

fprintf('Grid: Nx=%d  Ny=%d  Nz=%d\n', Nx, Ny, Nz);

%% --- CENTRE INDICES (slider origin = volume centre) ----------------------
cx = round(Nx/2);
cy = round(Ny/2);
cz = round(Nz/2);

%% --- COLOUR LIMITS -------------------------------------------------------
% Using the 99th percentile (not the absolute max) excludes rare outlier
% / edge-artifact pixels (common right at conductor edges in CST exports)
% that would otherwise stretch the colorbar out to ~100 and wash out all
% the meaningful detail in the 0-10/13 range. The true colorbar top is
% still reached by genuine high-intensity regions (e.g. near the coil),
% it just isn't dragged out by a handful of single-pixel spikes.
cl_B1p = [0, prctile(B1p(:), 99)];
cl_B1m = [0, prctile(B1m(:), 99)];
cl_SAR  = [0, prctile(SAR(:),  99)];

%% --- FIGURE LAYOUT -------------------------------------------------------
fig = figure(...
    'Name',        '3T Surface Coil - B1+  B1-  SAR10g @ 123 MHz', ...
    'NumberTitle', 'off', ...
    'Color',       [1 1 1], ...
    'Units',       'normalized', ...
    'Position',    [0.01 0.03 0.96 0.90]);

% Force the FIGURE-level colormap to jet as well. In MATLAB, per-axes
% colormaps can sometimes be overridden by the figure's own colormap
% property, which defaults to parula - that mismatch is what produced
% the dull purple/yellow "parula-looking" plots instead of true jet.
colormap(fig, jet(256));

% ---- geometry constants --------------------------------------------------
n_rows = 3;  n_cols = 3;

fig_left   = 0.07;
fig_right  = 0.01;
fig_top    = 0.05;
fig_bot    = 0.19;

total_w = 1 - fig_left - fig_right;
total_h = 1 - fig_top  - fig_bot;

col_gap = 0.04;
row_gap = 0.07;

ax_w = (total_w - (n_cols-1)*col_gap) / n_cols;
ax_h = (total_h - (n_rows-1)*row_gap) / n_rows;

fields     = {B1p,             B1m,             SAR};
clims      = {cl_B1p,          cl_B1m,          cl_SAR};
row_labels = {'B1+ (uT)',      'B1- (uT)',       'SAR10g (W/kg)'};
CMAP_NAME  = 'jet';   % full rainbow colormap: blue -> cyan -> green -> yellow -> red
CMAP_DATA  = jet(256); % explicit high-resolution version, avoids dull/interpolated look

ax  = gobjects(n_rows, n_cols);
img = gobjects(n_rows, n_cols);

% Colour used for all axis text (tick numbers, axis labels, titles)
% so they remain visible against the dark figure background.
TEXT_COLOR = [0 0 0];   % black

for r = 1:n_rows
    F  = fields{r};
    cl = clims{r};
    fn = row_labels{r};

    bot_edge = fig_bot + (n_rows - r) * (ax_h + row_gap);

    for c = 1:n_cols
        left_edge = fig_left + (c-1) * (ax_w + col_gap);

        ax(r,c) = axes('Parent', fig, ...
            'Position', [left_edge, bot_edge, ax_w, ax_h], ...
            'Color',    'w', ...
            'XColor',   TEXT_COLOR, ...
            'YColor',   TEXT_COLOR, ...
            'FontName', FONT_NAME, ...
            'FontSize', FONT_SIZE, ...
            'Box',      'on');
        colormap(ax(r,c), CMAP_DATA);
    end

    % -- XY panel (col 1) --
    axes(ax(r,1));
    img(r,1) = imagesc(x_mm, y_mm, squeeze(F(:,:,cz))');
    axis xy; axis equal tight;
    clim(cl);
    cb = colorbar;
    cb.Color    = TEXT_COLOR;
    cb.FontName = FONT_NAME;
    cb.FontSize = FONT_SIZE;
    xlabel('x (mm)', 'Color',TEXT_COLOR, 'FontName',FONT_NAME, 'FontSize',FONT_SIZE);
    ylabel('y (mm)', 'Color',TEXT_COLOR, 'FontName',FONT_NAME, 'FontSize',FONT_SIZE);
    title(sprintf('%s   XY plane   z = %.1f mm', fn, z_mm(cz)), ...
          'Color',TEXT_COLOR, 'FontName',FONT_NAME, 'FontSize',FONT_SIZE, 'FontWeight','bold');
    set(gca, 'XColor', TEXT_COLOR, 'YColor', TEXT_COLOR);

    % -- XZ panel (col 2) --
    axes(ax(r,2));
    img(r,2) = imagesc(x_mm, z_mm, squeeze(F(:,cy,:))');
    axis xy; axis equal tight;
    clim(cl);
    cb = colorbar;
    cb.Color    = TEXT_COLOR;
    cb.FontName = FONT_NAME;
    cb.FontSize = FONT_SIZE;
    xlabel('x (mm)', 'Color',TEXT_COLOR, 'FontName',FONT_NAME, 'FontSize',FONT_SIZE);
    ylabel('z (mm)', 'Color',TEXT_COLOR, 'FontName',FONT_NAME, 'FontSize',FONT_SIZE);
    title(sprintf('%s   XZ plane   y = %.1f mm', fn, y_mm(cy)), ...
          'Color',TEXT_COLOR, 'FontName',FONT_NAME, 'FontSize',FONT_SIZE, 'FontWeight','bold');
    set(gca, 'XColor', TEXT_COLOR, 'YColor', TEXT_COLOR);

    % -- YZ panel (col 3) --
    axes(ax(r,3));
    img(r,3) = imagesc(y_mm, z_mm, squeeze(F(cx,:,:))');
    axis xy; axis equal tight;
    clim(cl);
    cb = colorbar;
    cb.Color    = TEXT_COLOR;
    cb.FontName = FONT_NAME;
    cb.FontSize = FONT_SIZE;
    xlabel('y (mm)', 'Color',TEXT_COLOR, 'FontName',FONT_NAME, 'FontSize',FONT_SIZE);
    ylabel('z (mm)', 'Color',TEXT_COLOR, 'FontName',FONT_NAME, 'FontSize',FONT_SIZE);
    title(sprintf('%s   YZ plane   x = %.1f mm', fn, x_mm(cx)), ...
          'Color',TEXT_COLOR, 'FontName',FONT_NAME, 'FontSize',FONT_SIZE, 'FontWeight','bold');
    set(gca, 'XColor', TEXT_COLOR, 'YColor', TEXT_COLOR);
end

%% --- ROW LABELS on the left ----------------------------------------------
row_y = [fig_bot + 2*(ax_h+row_gap) + ax_h/2, ...
         fig_bot +    (ax_h+row_gap) + ax_h/2, ...
         fig_bot +                     ax_h/2];
row_colors = {[0.75 0.35 0.0], [0.0 0.35 0.65], [0.1 0.55 0.1]};
for r = 1:3
    annotation('textbox', [0.001, row_y(r)-0.03, 0.06, 0.06], ...
        'String',    row_labels{r}, ...
        'Color',     row_colors{r}, ...
        'FontName',  FONT_NAME, ...
        'FontSize',  FONT_SIZE, ...
        'FontWeight','bold', ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment',  'middle', ...
        'Rotation',  90);
end

%% --- TOP TITLE -----------------------------------------------------------
annotation('textbox',[0.10, 0.950, 0.78, 0.04], ...
    'String',    '3T RF Surface Coil Simulation  |  B1+   B1-   SAR10g  |  123 MHz  |  1W stimulated power', ...
    'Color',     [0.7 0.45 0.0], ...
    'FontName',  FONT_NAME, ...
    'FontSize',  FONT_SIZE, ...
    'FontWeight','bold', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment','center');

%% --- SLIDERS -------------------------------------------------------------
slider_cfg = {
    'Z-index   (scrolls XY plane)', 1, Nz, cz, 'z';
    'Y-index   (scrolls XZ plane)', 1, Ny, cy, 'y';
    'X-index   (scrolls YZ plane)', 1, Nx, cx, 'x';
};

for s = 1:3
    lft = 0.05 + (s-1)*0.33;
    mn  = slider_cfg{s,2};
    mx  = slider_cfg{s,3};
    st  = slider_cfg{s,4};
    dim = slider_cfg{s,5};

    uicontrol('Style','text', 'String', slider_cfg{s,1}, ...
        'Units','normalized', 'Position',[lft, 0.130, 0.28, 0.025], ...
        'BackgroundColor',[1 1 1], ...
        'ForegroundColor',[0.1 0.1 0.1], ...
        'FontName', FONT_NAME, 'FontSize', FONT_SIZE, ...
        'HorizontalAlignment','center');

    uicontrol('Style','slider', ...
        'Min', mn, 'Max', mx, 'Value', st, ...
        'SliderStep', [1/(mx-mn+1),  10/(mx-mn+1)], ...
        'Units','normalized', 'Position',[lft, 0.095, 0.26, 0.030], ...
        'BackgroundColor',[0.30 0.30 0.30], ...
        'Callback', @(src,~) update_view(src, fig, dim));

    uicontrol('Style','text', ...
        'String', sprintf('%d / %d', st, mx), ...
        'Units','normalized', 'Position',[lft+0.265, 0.095, 0.055, 0.030], ...
        'BackgroundColor',[1 1 1], ...
        'ForegroundColor',[0.0 0.5 0.0], ...
        'FontName', FONT_NAME, 'FontSize', FONT_SIZE, 'FontWeight','bold', ...
        'Tag', ['lbl_' dim]);

    switch dim
        case 'z', coord = z_mm(st);
        case 'y', coord = y_mm(st);
        case 'x', coord = x_mm(st);
    end
    uicontrol('Style','text', ...
        'String', sprintf('%.1f mm', coord), ...
        'Units','normalized', 'Position',[lft, 0.060, 0.28, 0.025], ...
        'BackgroundColor',[1 1 1], ...
        'ForegroundColor',[0.0 0.3 0.6], ...
        'FontName', FONT_NAME, 'FontSize', FONT_SIZE, ...
        'Tag', ['mm_' dim]);
end

uicontrol('Style','text', ...
    'String', 'Drag sliders to scroll through slices.  Sliders start at the centre of the volume (origin).', ...
    'Units','normalized', 'Position',[0.05, 0.025, 0.90, 0.025], ...
    'BackgroundColor',[1 1 1], ...
    'ForegroundColor',[0.35 0.35 0.35], ...
    'FontName', FONT_NAME, 'FontSize', FONT_SIZE);

%% --- STORE DATA FOR CALLBACK ---------------------------------------------
ud.fields     = fields;
ud.row_labels = row_labels;
ud.x_mm = x_mm;  ud.y_mm = y_mm;  ud.z_mm = z_mm;
ud.ax   = ax;
ud.img  = img;
ud.fontname = FONT_NAME;
ud.fontsize = FONT_SIZE;
ud.textcolor = TEXT_COLOR;
ud.plane_names = {'XY','XZ','YZ'};
ud.field_file_tags = {'B1p','B1m','SAR'};
ud.cur_idx = struct('x', cx, 'y', cy, 'z', cz);
set(fig, 'UserData', ud);

%% --- EXPORT BUTTONS (one under each of the 9 panels) ----------------------
% Each button exports EXACTLY that panel, at whatever slider position you
% have currently set, as its own clean PNG (white background, no title
% bar, no other panels - just that one heatmap + axes + colorbar).
for r = 1:n_rows
    bot_edge = fig_bot + (n_rows - r) * (ax_h + row_gap);
    for c = 1:n_cols
        left_edge = fig_left + (c-1) * (ax_w + col_gap);
        btn_w = ax_w * 0.55;
        btn_h = 0.018;
        btn_left = left_edge + (ax_w - btn_w)/2;
        % place button in the gap between this panel and the one below it
        % (or, for the bottom row, just above the slider area)
        btn_bot  = bot_edge - 0.038;

        uicontrol('Style','pushbutton', ...
            'String', 'Export this panel', ...
            'Units','normalized', ...
            'Position',[btn_left, btn_bot, btn_w, btn_h], ...
            'FontName', FONT_NAME, 'FontSize', 8, ...
            'BackgroundColor',[0.85 0.85 0.85], ...
            'Callback', @(src,~) export_panel(fig, r, c));
    end
end

disp(' ');
disp('==============================================');
disp(' Viewer ready!  Drag the sliders to scroll.');
disp(' Click "Export this panel" under any plot to');
disp(' save THAT panel, at its CURRENT slider position,');
disp(' as a clean standalone PNG file.');
disp('==============================================');


%% =========================================================================
%  CALLBACK - runs every time a slider moves
% =========================================================================
function update_view(src, fig, dim)
    ud  = get(fig, 'UserData');
    idx = round(src.Value);

    lbl    = findobj(fig, 'Tag', ['lbl_' dim]);
    lbl_mm = findobj(fig, 'Tag', ['mm_' dim]);

    switch dim
        case 'z'
            N    = length(ud.z_mm);
            coord = ud.z_mm(idx);
        case 'y'
            N    = length(ud.y_mm);
            coord = ud.y_mm(idx);
        case 'x'
            N    = length(ud.x_mm);
            coord = ud.x_mm(idx);
    end

    set(lbl,    'String', sprintf('%d / %d', idx, N));
    set(lbl_mm, 'String', sprintf('%.1f mm', coord));

    % remember the current slider index for this dimension, so the
    % export buttons can always grab the latest position
    ud.cur_idx.(dim) = idx;
    set(fig, 'UserData', ud);

    FONT_NAME = ud.fontname;
    FONT_SIZE = ud.fontsize;
    TEXT_COLOR = ud.textcolor;

    for r = 1:3
        F  = ud.fields{r};
        fn = ud.row_labels{r};

        switch dim
            case 'z'
                set(ud.img(r,1), 'CData', squeeze(F(:,:,idx))');
                title(ud.ax(r,1), ...
                    sprintf('%s   XY plane   z = %.1f mm', fn, ud.z_mm(idx)), ...
                    'Color',TEXT_COLOR,'FontName',FONT_NAME,'FontSize',FONT_SIZE,'FontWeight','bold');

            case 'y'
                set(ud.img(r,2), 'CData', squeeze(F(:,idx,:))');
                title(ud.ax(r,2), ...
                    sprintf('%s   XZ plane   y = %.1f mm', fn, ud.y_mm(idx)), ...
                    'Color',TEXT_COLOR,'FontName',FONT_NAME,'FontSize',FONT_SIZE,'FontWeight','bold');

            case 'x'
                set(ud.img(r,3), 'CData', squeeze(F(idx,:,:))');
                title(ud.ax(r,3), ...
                    sprintf('%s   YZ plane   x = %.1f mm', fn, ud.x_mm(idx)), ...
                    'Color',TEXT_COLOR,'FontName',FONT_NAME,'FontSize',FONT_SIZE,'FontWeight','bold');
        end
    end
end


%% =========================================================================
%  EXPORT_PANEL - saves exactly one panel (row r, column c) as a clean,
%  standalone PNG file, using whatever slider position is CURRENTLY shown
%  for that panel. No title bar, no other panels, no extra white space.
% =========================================================================
function export_panel(fig, r, c)
    ud = get(fig, 'UserData');

    src_ax = ud.ax(r,c);

    % Build a fresh, single-axes figure and copy the visual content
    % of the source panel into it exactly as currently displayed.
    fig_export = figure('Color','w', 'Units','centimeters', ...
                         'Position',[2 2 10 9], 'Visible','off');
    colormap(fig_export, jet(256));   % set figure-level colormap explicitly, same fix as the main viewer
    new_ax = copyobj(src_ax, fig_export);
    set(new_ax, 'Units','normalized', 'OuterPosition',[0 0 1 1], ...
                'Position',[0.16 0.14 0.68 0.74]);

    % Re-apply colormap on the axes itself too, to be fully explicit
    colormap(new_ax, jet(256));

    % Re-create the colorbar on the copied axes (copyobj sometimes drops it)
    has_cb = ~isempty(findobj(fig_export, 'Type', 'ColorBar'));
    if ~has_cb
        cb = colorbar(new_ax);
        cb.FontName = ud.fontname;
        cb.FontSize = ud.fontsize;
        cb.Color    = ud.textcolor;
    end

    % Build filename from field name + plane + current slider coordinate
    field_tag  = ud.field_file_tags{r};
    plane_name = ud.plane_names{c};

    switch c
        case 1, coord_str = sprintf('z%.1f', ud.z_mm(ud.cur_idx.z));
        case 2, coord_str = sprintf('y%.1f', ud.y_mm(ud.cur_idx.y));
        case 3, coord_str = sprintf('x%.1f', ud.x_mm(ud.cur_idx.x));
    end
    coord_str = strrep(coord_str, '.', 'p');
    coord_str = strrep(coord_str, '-', 'm');

    out_name = sprintf('Export_%s_%s_%s.png', field_tag, plane_name, coord_str);

    exportgraphics(fig_export, out_name, 'Resolution', 300, 'BackgroundColor','white');
    close(fig_export);

    fprintf('Saved: %s\n', out_name);
    msgbox(sprintf('Saved as:\n%s\n\n(in your current MATLAB folder)', out_name), ...
           'Panel exported', 'modal');
end
