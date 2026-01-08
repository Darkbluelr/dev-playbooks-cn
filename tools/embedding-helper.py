#!/usr/bin/env python3
"""
DevBooks Embedding - Python 辅助工具
提供更精确的向量计算和本地模型支持
"""

import json
import sys
import argparse
from pathlib import Path
from typing import List, Tuple, Optional
import math


def cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """计算余弦相似度"""
    if len(vec1) != len(vec2):
        raise ValueError("向量维度不匹配")

    dot_product = sum(a * b for a, b in zip(vec1, vec2))
    norm1 = math.sqrt(sum(a * a for a in vec1))
    norm2 = math.sqrt(sum(b * b for b in vec2))

    if norm1 == 0 or norm2 == 0:
        return 0.0

    return dot_product / (norm1 * norm2)


def search_similar(
    query_vector: List[float],
    vector_db_dir: Path,
    top_k: int = 5,
    threshold: float = 0.7
) -> List[Tuple[str, float]]:
    """搜索相似向量"""
    index_file = vector_db_dir / "index.tsv"

    if not index_file.exists():
        print("错误: 索引文件不存在", file=sys.stderr)
        return []

    results = []

    with open(index_file, 'r', encoding='utf-8') as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) != 2:
                continue

            file_path, hash_value = parts
            vector_file = vector_db_dir / f"{hash_value}.json"

            if not vector_file.exists():
                continue

            try:
                with open(vector_file, 'r', encoding='utf-8') as vf:
                    file_vector = json.load(vf)

                similarity = cosine_similarity(query_vector, file_vector)

                if similarity >= threshold:
                    results.append((file_path, similarity))

            except Exception as e:
                print(f"警告: 处理 {file_path} 时出错: {e}", file=sys.stderr)
                continue

    # 排序并返回 top-k
    results.sort(key=lambda x: x[1], reverse=True)
    return results[:top_k]


def format_results(results: List[Tuple[str, float]], show_snippet: bool = True, project_root: Optional[Path] = None):
    """格式化搜索结果"""
    if not results:
        print("未找到相关结果")
        return

    print(f"\n找到 {len(results)} 个相关结果:\n")

    for i, (file_path, score) in enumerate(results, 1):
        print(f"{i}. [{score:.4f}] {file_path}")

        if show_snippet and project_root:
            full_path = project_root / file_path
            if full_path.exists():
                print("---")
                try:
                    with open(full_path, 'r', encoding='utf-8') as f:
                        lines = f.readlines()[:10]
                        for line in lines:
                            print(f"  {line.rstrip()}")
                except Exception as e:
                    print(f"  无法读取文件: {e}")
                print()


def main():
    parser = argparse.ArgumentParser(description='DevBooks Embedding Python 辅助工具')

    parser.add_argument('command', choices=['search', 'similarity'],
                        help='命令：search（搜索）, similarity（计算相似度）')

    parser.add_argument('--query-vector', type=str,
                        help='查询向量 JSON 文件路径')

    parser.add_argument('--vector-db', type=str,
                        default='.devbooks/embeddings',
                        help='向量数据库目录')

    parser.add_argument('--top-k', type=int, default=5,
                        help='返回结果数量')

    parser.add_argument('--threshold', type=float, default=0.7,
                        help='相似度阈值')

    parser.add_argument('--no-snippet', action='store_true',
                        help='不显示代码片段')

    parser.add_argument('--project-root', type=str, default='.',
                        help='项目根目录')

    parser.add_argument('--vec1', type=str,
                        help='向量1（JSON 数组）')

    parser.add_argument('--vec2', type=str,
                        help='向量2（JSON 数组）')

    args = parser.parse_args()

    if args.command == 'search':
        if not args.query_vector:
            print("错误: --query-vector 必须指定", file=sys.stderr)
            sys.exit(1)

        query_vector_file = Path(args.query_vector)
        if not query_vector_file.exists():
            print(f"错误: 查询向量文件不存在: {query_vector_file}", file=sys.stderr)
            sys.exit(1)

        with open(query_vector_file, 'r', encoding='utf-8') as f:
            query_vector = json.load(f)

        vector_db_dir = Path(args.vector_db)
        project_root = Path(args.project_root)

        results = search_similar(
            query_vector,
            vector_db_dir,
            top_k=args.top_k,
            threshold=args.threshold
        )

        format_results(results, not args.no_snippet, project_root)

    elif args.command == 'similarity':
        if not args.vec1 or not args.vec2:
            print("错误: --vec1 和 --vec2 必须指定", file=sys.stderr)
            sys.exit(1)

        vec1 = json.loads(args.vec1)
        vec2 = json.loads(args.vec2)

        similarity = cosine_similarity(vec1, vec2)
        print(f"{similarity:.6f}")


if __name__ == '__main__':
    main()
