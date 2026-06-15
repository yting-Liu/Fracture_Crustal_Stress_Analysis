function process_profile(id)
    % 设置路径

    profile_folder = '/xxx/profiles';
    result_folder = '/xxx/organize_wid_amp_shear_normal';
    output_folder = '/xxx/picked_coords';

    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    profile_files = dir(fullfile(profile_folder, [id, '_*']));
    if isempty(profile_files)
        fprintf('未找到剖面文件: ID %s\n', id);
        return;
    end
    profile_path = fullfile(profile_folder, profile_files(1).name);
    data = load(profile_path);
    if size(data,2) < 2
        error('文件格式错误，至少应为两列 X-Y 坐标');
    end

    output_file = fullfile(output_folder, [id '_picked_points.txt']);
    if exist(output_file, 'file')
        fprintf('⚠️ 已存在坐标文件: %s\n', output_file);
        choice = input('输入 [o] 覆盖 / [s] 跳过 / [v] 查看已有图: ', 's');
        switch lower(choice)
            case 's'
                disp('跳过处理。'); return;
            case 'v'
                old_data = load(output_file);
                figure('Name', ['查看已选点 ID ' id]);
                plot(data(:,1), data(:,2), 'b.-'); hold on;
                plot(old_data(:,1), old_data(:,2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
                title(['已有坐标 - ID ' id]);
                xlabel('X'); ylabel('Y'); grid on;
                legend('剖面数据', '已选点');
                return;
            case 'o'
                disp('重新选择坐标...');
            otherwise
                disp('默认重新选择...');
        end
    end

    done = false;
    while ~done
        clf;
        plot(data(:,1), data(:,2), 'b.-');
        title(['Profile ID ' id]);
        xlabel('X'); ylabel('Y'); grid on;
        disp('👉 点击图上选择点，按 Enter 结束...');
        [x, y] = ginput;

        hold on;
        plot(x, y, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
        for i = 1:length(x)
            text(x(i), y(i), sprintf(' %d', i), 'FontSize', 10, 'Color', 'red');
        end
        hold off;

        if length(x) < 2
            disp('⚠️ 你选择的点太少，请至少选择两个点。');
            continue;
        end

        answer = input('确认这些点？(y/n): ', 's');
        if strcmpi(answer, 'y')
            done = true;
        else
            disp('请重新选择...');
        end
    end

    fid = fopen(output_file, 'w');
    for i = 1:length(x)
        fprintf(fid, '%.6f %.6f\n', x(i), y(i));
    end
    fclose(fid);
    fprintf('✅ 已保存至: %s\n', output_file);
end