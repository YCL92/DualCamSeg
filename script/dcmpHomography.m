function motion = dcmpHomography(h_matrix, k_matrix)
% this function decompose a given 3x3 homography
% into rotation, translation and plane normal. Usually
% the decomposition has four possible solutions
% (two individuals and two inverse versions), the two
% inverse version will be removed from output.
% by yucheng.l@outlook.com 2018-01-22

%% decompose homography
[list_motion, num_solution] = decomposeHomographyMat(h_matrix, k_matrix);

% not a valid decomposition
if num_solution ~= 4
    motion = [];
    return;
end

if isequal(cell2mat(list_motion.R(1)), cell2mat(list_motion.R(2)))
    m_temp.rot1 = cell2mat(list_motion.R(1));
    m_temp.trans1 = cell2mat(list_motion.t(1));
    m_temp.norm1 = cell2mat(list_motion.n(1));
    m_temp.rot2 = cell2mat(list_motion.R(3));
    m_temp.trans2 = cell2mat(list_motion.t(3));
    m_temp.norm2 = cell2mat(list_motion.n(3));
else
    m_temp.rot1 = cell2mat(list_motion.R(1));
    m_temp.trans1 = cell2mat(list_motion.t(1));
    m_temp.norm1 = cell2mat(list_motion.n(1));
    m_temp.rot2 = cell2mat(list_motion.R(2));
    m_temp.trans2 = cell2mat(list_motion.t(2));
    m_temp.norm2 = cell2mat(list_motion.n(2));
end

% check rotation angle
vct1 = m_temp.rot1*[1, 1, 1]';
vct2 = m_temp.rot2*[1, 1, 1]';
rot_angle(1) = abs(atan2d(norm(cross(vct1', [1, 1, 1])), dot(vct1', [1, 1, 1])));
rot_angle(2) = abs(atan2d(norm(cross(vct2', [1, 1, 1])), dot(vct2', [1, 1, 1])));

if rot_angle(1) > rot_angle(2)
    motion.rot1 = m_temp.rot1;
    motion.trans1 = m_temp.trans1;
    motion.norm1 = m_temp.norm1;
    motion.rot2 = m_temp.rot2;
    motion.trans2 = m_temp.trans2;
    motion.norm2 = m_temp.norm2;
else
    motion.rot1 = m_temp.rot2;
    motion.trans1 = m_temp.trans2;
    motion.norm1 = m_temp.norm2;
    motion.rot2 = m_temp.rot1;
    motion.trans2 = m_temp.trans1;
    motion.norm2= m_temp.norm1;
end