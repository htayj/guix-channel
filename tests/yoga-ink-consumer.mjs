// SPDX-License-Identifier: GPL-3.0-or-later
// Source-derived flex_shrink_flex_grow_row from Yoga v3.2.1's
// javascript/tests/generated/YGFlexTest.test.ts, plus both npm exports.
import assert from 'node:assert/strict';
import Yoga, {Direction, FlexDirection, PositionType} from 'yoga-layout';
import {loadYoga} from 'yoga-layout/load';

function shrinkRow(yoga) {
  const config = yoga.Config.create();
  const root = yoga.Node.create(config);
  try {
    root.setFlexDirection(FlexDirection.Row);
    root.setPositionType(PositionType.Absolute);
    root.setWidth(500);
    root.setHeight(500);
    const children = [yoga.Node.create(config), yoga.Node.create(config)];
    for (const [index, child] of children.entries()) {
      child.setFlexShrink(1);
      child.setWidth(500);
      child.setHeight(100);
      root.insertChild(child, index);
    }
    const layout = node => [node.getComputedLeft(), node.getComputedTop(), node.getComputedWidth(), node.getComputedHeight()];
    root.calculateLayout(undefined, undefined, Direction.LTR);
    assert.deepEqual(layout(root), [0, 0, 500, 500]);
    const ltr = children.map(layout);
    assert.deepEqual(ltr, [[0, 0, 250, 100], [250, 0, 250, 100]]);
    root.calculateLayout(undefined, undefined, Direction.RTL);
    assert.deepEqual(layout(root), [0, 0, 500, 500]);
    const rtl = children.map(layout);
    assert.deepEqual(rtl, [[250, 0, 250, 100], [0, 0, 250, 100]]);
    return {ltr, rtl};
  } finally {
    root.freeRecursive();
    config.free();
  }
}
const eager = shrinkRow(Yoga);
const lazy = shrinkRow(await loadYoga());
assert.deepEqual(lazy, eager);
console.log(JSON.stringify({contract: 'yoga-layout-3.2.1-source-flex-shrink', exports: ['yoga-layout', 'yoga-layout/load'], ...eager}));
