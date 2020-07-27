package Roots::Surnames;
use v5.12;
use utf8;

# This list of surnames could in theory be generated on the fly, but
# having it hard coded here saves us an SQL call and allows us to tweak things
# like the order of the surnames in cases where, e.g., Wong 黃 is much more
# common than Wong 王 so we list it first. At this point most of the data has
# been entered, so if any new surnames pop up we can add them here by hand.
our @menu = (['dummy'],
['區', 'Au', 'Ōu', 'ou1'],
['歐', 'Au', 'Ōu', 'ou1'],
['歐陽', 'Au Yeung', 'Ōuyáng', 'ou1 yang2'],
['鮑', 'Bau, Pao', 'Bào', 'bao4'],
['邦', 'Bong', 'Bāng', 'bang1'],
['陳', 'Chan, Chin', 'Chén', 'chen2'],
['巢', 'Chao', 'Cháo', 'chao2'],
['周', 'Chau, Chow', 'Zhōu', 'zhou1'],
['鄒', 'Chau, Chow', 'Zōu', 'zou1'],
['瘳', 'Chau', 'Chōu', 'chou1'],
['鄭', 'Cheng', 'Zhèng', 'zheng4'],
['卓', 'Cheuk', 'Zhuó', 'zhuo2'],
['張', 'Cheung', 'Zhāng', 'zhang1'],
['池', 'Chi', 'Chí', 'chi2'],
['蔣', 'Chiang', 'Jiǎng', 'jiang3'],
['錢', 'Chien, Chin', 'Qián', 'qian2'],
['戚', 'Chik', 'Qī', 'qi1'],
['赤', 'Chik', 'Chì', 'chi4'],
['秦', 'Chin', 'Qín', 'qin2'],
['程', 'Ching', 'Chéng', 'cheng2'],
['趙', 'Chiu, Chu, Jew', 'Zhào', 'zhao4'],
['肖', 'Chiu', 'Xiào', 'xiao4'],
['曹', 'Cho, Tso', 'Cáo', 'cao2'],
['蔡', 'Choi, Toy, Tsoi', 'Cài', 'cai4'],
['朱', 'Chu, Gee', 'Zhū', 'zhu1'],
['崔', 'Chui', 'Cuī', 'cui1'],
['祝', 'Chuk', 'Zhù', 'zhu4'],
['鍾', 'Chung', 'Zhōng', 'zhong1'],
['戴', 'Dai, Tai', 'Dài', 'dai4'],
['謝', 'Der, Tse', 'Xiè', 'xie4'],
['翟', 'Dik', 'Dí', 'di2'],
['奠', 'Din', 'Diàn', 'dian4'],
['刁', 'Diu', 'Diāo', 'diao1'],
['范', 'Fan', 'Fàn', 'fan4'],
['樊', 'Fan', 'Fán', 'fan2'],
['霍', 'Fok', 'Huò', 'huo4'],
['方', 'Fong', 'Fāng', 'fang1'],
['鄺', 'Fong, Kwong', 'Kuàng', 'kuang4'],
['傅', 'Fu', 'Fù', 'fu4'],
['苻', 'Fu', 'Fú', 'fu2'],
['馮', 'Fung', 'Féng', 'feng2'],
['郟', 'Gap', 'Jiá', 'jia2'],
['甄', 'Gin, Yan', 'Zhēn', 'zhen1'],
['夏', 'Ha', 'Xià', 'xia4'],
['侯', 'Hau', 'Hóu', 'hou2'],
['何', 'Ho', 'Hé', 'he2'],
['賀', 'Ho', 'Hè', 'he4'],
['譚', 'Hom, Tam', 'Tán', 'tan2'],
['韓', 'Hon', 'Hán', 'han2'],
['康', 'Hong', 'Kāng', 'kang1'],
['項', 'Hong', 'Xiàng', 'xiang4'],
['候', 'Hou', 'Hòu', 'hou4'],
['禤', 'Huen', 'Xuān', 'xuan1'],
['許', 'Hui', 'Xǔ', 'xu3'],
['熊', 'Hung', 'Xióng', 'xiong2'],
['洪', 'Hung', 'Hóng', 'hong2'],
['孔', 'Hung', 'Kǒng', 'kong3'],
['詹', 'Jim', 'Zhān', 'zhan1'],
['甘', 'Kam', 'Gān', 'gan1'],
['金', 'Kam', 'Jīn', 'jin1'],
['簡', 'Kan', 'Jiǎn', 'jian3'],
['姜', 'Keung', 'Jiāng', 'jiang1'],
['揭', 'Kit', 'Jiē', 'jie1'],
['高', 'Ko', 'Gāo', 'gao1'],
['江', 'Kong', 'Jiāng', 'jiang1'],
['葛', 'Kot', 'Gě', 'ge3'],
['古', 'Ku', 'Gǔ', 'gu3'],
['顧', 'Ku', 'Gù', 'gu4'],
['股', 'Ku', 'Gǔ', 'gu3'],
['龔', 'Kung', 'Gōng', 'gong1'],
['關', 'Kwan', 'Guān', 'guan1'],
['郭', 'Kwok', 'Guō', 'guo1'],
['官', 'Kwoon', 'Guān', 'guan1'],
['黎', 'Lai', 'Lí', 'li2'],
['賴', 'Lai', 'Lài', 'lai4'],
['林', 'Lam, Lum', 'Lín', 'lin2'],
['藍', 'Lam', 'Lán', 'lan2'],
['劉', 'Lau', 'Liú', 'liu2'],
['李', 'Lee', 'Lǐ', 'li3'],
['利', 'Lee', 'Lì', 'li4'],
['梁', 'Leung', 'Liáng', 'liang2'],
['連', 'Lin', 'Lián', 'lian2'],
['練', 'Lin', 'Liàn', 'lian4'],
['凌', 'Ling', 'Líng', 'ling2'],
['廖', 'Liu', 'Liào', 'liao4'],
['盧', 'Lo', 'Lú', 'lu2'],
['勞', 'Lo', 'Láo', 'lao2'],
['羅', 'Lo, Lor', 'Luó', 'luo2'],
['駱', 'Lok', 'Luò', 'luo4'],
['洛', 'Lok', 'Luò', 'luo4'],
['雷', 'Louie, Lui', 'Léi', 'lei2'],
['呂', 'Lui', 'Lǚ', 'lv3'],
['陸', 'Luk', 'Lù', 'lu4'],
['龍', 'Lung', 'Lóng', 'long2'],
['馬', 'Ma, Mar', 'Mǎ', 'ma3'],
['麥', 'Mak', 'Mài', 'mai4'],
['文', 'Man, Mun', 'Wén', 'wen2'],
['萬', 'Man', 'Wàn', 'wan4'],
['孟', 'Mang', 'Mèng', 'meng4'],
['繆', 'Mau', 'Móu', 'mou2'],
['巫', 'Mo', 'Wū', 'wu1'],
['毛', 'Mo', 'Máo', 'mao2'],
['武', 'Mo', 'Wǔ', 'wu3'],
['莫', 'Mok', 'Mò', 'mo4'],
['梅', 'Moy', 'Méi', 'mei2'],
['閔', 'Mun', 'Mǐn', 'min3'],
['蒙', 'Mung', 'Méng', 'meng2'],
['伍', 'Ng', 'Wǔ', 'wu3'],
['吳', 'Ng', 'Wú', 'wu2'],
['倪', 'Ngai', 'Ní', 'ni2'],
['魏', 'Ngai', 'Wèi', 'wei4'],
['顏', 'Ngan', 'Yán', 'yan2'],
['敖', 'Ngo', 'Áo', 'ao2'],
['岳', 'Ngok', 'Yuè', 'yue4'],
['寧', 'Ning', 'Níng', 'ning2'],
['聶', 'Nip', 'Niè', 'nie4'],
['柯', 'Or', 'Kē', 'ke1'],
['白', 'Pak', 'Bái', 'bai2'],
['彭', 'Pang', 'Péng', 'peng2'],
['包', 'Pao', 'Bāo', 'bao1'],
['龐', 'Pong', 'Páng', 'pang2'],
['潘', 'Poon, Pun', 'Pān', 'pan1'],
['盤', 'Poon', 'Pán', 'pan2'],
['辛', 'San, Sun', 'Xīn', 'xin1'],
['司徒', 'Seto', 'Sītú', 'si1 tu2'],
['施', 'She', 'Shī', 'shi1'],
['石', 'Shek', 'Shí', 'shi2'],
['佘', 'Sher', 'Shé', 'she2'],
['是', 'Shi', 'Shì', 'shi4'],
['岑', 'Shum', 'Cén', 'cen2'],
['淳', 'Shun', 'Chún', 'chun2'],
['色', 'Sik', 'Sè', 'se4'],
['單', 'Sin', 'Shàn', 'shan4'],
['冼', 'Sin', 'Shěng', 'sheng3'],
['成', 'Sing', 'Chéng', 'cheng2'],
['薛', 'Sit', 'Xuē', 'xue1'],
['蕭', 'Siu', 'Xiāo', 'xiao1'],
['蘇', 'So', 'Sū', 'su1'],
['孫', 'Suen, Sun', 'Sūn', 'sun1'],
['沈', 'Sum', 'Chén', 'chen2'],
['宋', 'Sung', 'Sòng', 'song4'],
['談', 'Tam', 'Tán', 'tan2'],
['覃', 'Tam', 'Tán', 'tan2'],
['鄧', 'Tang', 'Dèng', 'deng4'],
['滕', 'Tang', 'Téng', 'teng2'],
['禢', 'Tap', 'Tā', 'ta1'],
['田', 'Tin', 'Tián', 'tian2'],
['丁', 'Ting', 'Dīng', 'ding1'],
['杜', 'To', 'Dù', 'du4'],
['涂', 'To', 'Tú', 'tu2'],
['湯', 'Tong', 'Tāng', 'tang1'],
['唐', 'Tong', 'Táng', 'tang2'],
['曾', 'Tsang', 'Zēng', 'zeng1'],
['徐', 'Tsui', 'Xú', 'xu2'],
['衛', 'Wai, Wei', 'Wèi', 'wei4'],
['韋', 'Wai', 'Wéi', 'wei2'],
['溫', 'Wan, Won', 'Wēn', 'wen1'],
['尹', 'Wan', 'Yǐn', 'yin3'],
['屈', 'Wat', 'Qū', 'qu1'],
['黃', 'Wong', 'Huáng', 'huang2'],
['王', 'Wong', 'Wáng', 'wang2'],
['胡', 'Woo, Wu', 'Hú', 'hu2'],
['任', 'Yam', 'Rèn', 'ren4'],
['殷', 'Yan', 'Yīn', 'yin1'],
['丘', 'Yau', 'Qiū', 'qiu1'],
['邱', 'Yau', 'Qiū', 'qiu1'],
['余', 'Yee, Yu', 'Yú', 'yu2'],
['楊', 'Yeung', 'Yáng', 'yang2'],
['嚴', 'Yim', 'Yán', 'yan2'],
['英', 'Ying', 'Yīng', 'ying1'],
['葉', 'Yip', 'Yè', 'ye4'],
['姚', 'Yiu', 'Yáo', 'yao2'],
['饒', 'Yiu', 'Ráo', 'rao2'],
['茹', 'Yu', 'Rú', 'ru2'],
['俞', 'Yu', 'Yú', 'yu2'],
['阮', 'Yuen', 'Ruǎn', 'ruan3'],
['袁', 'Yuen', 'Yuán', 'yuan2'],
['遠', 'Yuen', 'Yuǎn', 'yuan3'],
['翁', 'Yung', 'Wēng', 'weng1'],
['容', 'Yung', 'Róng', 'rong2'],
);

1;
