export const COLOR = {
  primary: '#0A874D',
  primaryDark: '#006542',
  accent: '#FBCC14',
  accentAlt: '#F9A22B',
  admin: '#0F5C3E',
  inkSoft: '#10251A',
  textSecondary: '#5B665F',
  textMuted: '#8A948E',
  border: '#DCE3DE',
  surfaceMuted: '#F6F8F5',
  white: '#FFFFFF',
  bgCode: '#0D1F19',
  bgCodeDark: '#05100C',
  error: '#D32F2F',
  infoBg: '#EAF2FB',
  infoBorder: '#BFDBFE',
  infoText: '#1E3A5F',
  warnBg: '#FEF3E2',
  warnBorder: '#FDE0A8',
  warnText: '#7A4A00',
};

export const ROLE_COLOR = {
  pelanggan: '#0A874D',
  kru: '#006542',
  admin: '#0F5C3E',
};

// pdfmake doesn't support #RRGGBBAA (hex+alpha suffix) fillColors — it
// silently produces garbage colors instead of erroring. Solid light tints
// computed ahead of time instead of blending at render time.
export const ROLE_BADGE = {
  pelanggan: { bg: '#E6F3EC', border: '#B9DEC9', text: '#0A874D' },
  kru: { bg: '#E3EFEA', border: '#AFD1C4', text: '#006542' },
  admin: { bg: '#E5EEE9', border: '#B4D3C4', text: '#0F5C3E' },
};

export const PAGE = {
  size: 'A4',
  layout: 'landscape',
  widthPt: 841.89,
  heightPt: 595.28,
  margin: { left: 42, top: 42, right: 42, bottom: 56 },
};

export const CONTENT_WIDTH = PAGE.widthPt - PAGE.margin.left - PAGE.margin.right;

// pdfmake only supports 4 slots per family (normal/bold/italics/bolditalics),
// so each weight we need beyond regular+bold gets its own family name.
export const FONTS = {
  Montserrat: {
    normal: 'fonts/Montserrat-400.ttf',
    bold: 'fonts/Montserrat-700.ttf',
    italics: 'fonts/Montserrat-400.ttf',
    bolditalics: 'fonts/Montserrat-700.ttf',
  },
  MontserratMedium: {
    normal: 'fonts/Montserrat-500.ttf',
    bold: 'fonts/Montserrat-700.ttf',
    italics: 'fonts/Montserrat-500.ttf',
    bolditalics: 'fonts/Montserrat-700.ttf',
  },
  MontserratSemiBold: {
    normal: 'fonts/Montserrat-600.ttf',
    bold: 'fonts/Montserrat-700.ttf',
    italics: 'fonts/Montserrat-600.ttf',
    bolditalics: 'fonts/Montserrat-700.ttf',
  },
  MontserratExtraBold: {
    normal: 'fonts/Montserrat-800.ttf',
    bold: 'fonts/Montserrat-800.ttf',
    italics: 'fonts/Montserrat-800.ttf',
    bolditalics: 'fonts/Montserrat-800.ttf',
  },
  JetBrainsMono: {
    normal: 'fonts/JetBrainsMono-400.ttf',
    bold: 'fonts/JetBrainsMono-700.ttf',
    italics: 'fonts/JetBrainsMono-400.ttf',
    bolditalics: 'fonts/JetBrainsMono-700.ttf',
  },
  JetBrainsMonoMedium: {
    normal: 'fonts/JetBrainsMono-500.ttf',
    bold: 'fonts/JetBrainsMono-700.ttf',
    italics: 'fonts/JetBrainsMono-500.ttf',
    bolditalics: 'fonts/JetBrainsMono-700.ttf',
  },
};
